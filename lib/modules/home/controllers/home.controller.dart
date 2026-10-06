import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../data/models/models.dart';
import '../services/home.service.dart';

/// Home-page lifecycle only: version reporting/update checks, the one-time
/// notification permission prompt and the user's molecules refresh.
///
/// The atoms list no longer lives here — Home renders the user's molecules
/// and each molecule screen owns its own atom list ([MoleculeController]).
class HomeController extends GetxController with WidgetsBindingObserver {
  final VersionService _version = Get.find<VersionService>();
  final CategoryService _categories = Get.find<CategoryService>();
  final StorageService _storage = Get.find<StorageService>();
  final HomeService _home = Get.find<HomeService>();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    if (Get.testMode) return;
    // Deferred one frame: the controller is constructed lazily while the
    // first HomePage build is still running, and mutating Rx state inside a
    // build phase trips flutter's markNeedsBuild guard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Molecules come from the user's own list; refreshed silently so the
      // home list keeps its last state on failure.
      _categories.refresh();
    });
    // Best-effort telemetry — staggered so it doesn't compete for the first
    // socket while the workspace request is still in flight.
    Future<void>.delayed(const Duration(seconds: 3), reportUserVersion);
    // Ask for notification access on entry: the background-recording
    // notification (with its Pause/Stop controls) depends on it.
    Future<void>.delayed(const Duration(milliseconds: 900), _promptNotifications);
  }

  /// Prompts for notification permission once ever (persisted) — testers saw it
  /// on every launch. Skipped entirely when it is already granted.
  Future<void> _promptNotifications() async {
    final permissions = Get.find<PermissionService>();
    if (permissions.notificationPromptShown) return;
    permissions.notificationPromptShown = true;

    if (await permissions.isNotificationAllowed()) return;

    // Ask once, ever: after the first prompt, the choice is the user's.
    if (permissions.notificationPromptAskedBefore) return;

    final context = Get.context;
    if (context == null || !context.mounted) return;

    // Persist before showing, so even a crash mid-dialog counts as asked.
    await permissions.markNotificationPromptAsked();
    if (!context.mounted) return;

    final enable = await AppDialog.confirm(
      context: context,
      title: AppLocales.permission.notificationTitle.tr,
      message: AppLocales.permission.notificationMessage.tr,
      confirmLabel: AppLocales.permission.notificationEnable.tr,
      confirmColor: context.colors.primary,
      cancelColor: context.colors.error,
    );

    if (enable) {
      await permissions.ensureNotification(
        title: AppLocales.permission.notificationTitle.tr,
        message: AppLocales.permission.notificationMessage.tr,
      );
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVersionOnResume();
    }
  }

  Future<void> reportUserVersion() async {
    try {
      await _version.reportUserVersion(
        version: AppInfo.version,
        buildNumber: AppInfo.versionCode,
      );
    } catch (error) {
      debugPrint('Error: $error');
    }
  }

  Future<void> _checkVersionOnResume() async {
    try {
      final result = await _version.getCurrent(
        version: AppInfo.version,
        buildNumber: AppInfo.versionCode,
      );
      if (result.success && result.data != null) {
        final version = result.data!;
        _storage.setSkipPremium(version.skipPremium);

        if (version.mustUpdate) {
          AppRoutes.toSplash();
          return;
        }

        if (version.updateRequired) {
          final context = Get.context;
          if (context != null && context.mounted) {
            final title = (version.title?.trim().isNotEmpty == true)
                ? version.title!.trim()
                : AppLocales.update.title.tr;
            final message = (version.description?.trim().isNotEmpty == true)
                ? version.description!.trim()
                : AppLocales.update.message.tr;
            await AppDialog.update(
              context: context,
              title: title,
              message: message,
              onUpdate: () async {
                if (version.storeUrl != null && version.storeUrl!.isNotEmpty) {
                  final uri = Uri.tryParse(version.storeUrl!);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
            );
          }
        }
      }
    } catch (error) {
      debugPrint('Resume version check error: $error');
    }
  }

  // ============================================================
  // MOLECULE EXPANSION (home accordion)
  // ============================================================

  /// Molecules the user expanded inline on home.
  final RxSet<String> expandedMolecules = <String>{}.obs;

  /// First-page atoms per expanded molecule — lazily fetched on first
  /// expand and kept fresh by socket atom events via
  /// [refreshExpandedMolecules].
  final RxMap<String, List<AtomModel>> moleculeAtoms =
      <String, List<AtomModel>>{}.obs;

  /// Molecules whose inline atoms are currently loading.
  final RxSet<String> loadingMolecules = <String>{}.obs;

  /// Toggles a molecule's inline atom list on home; the first expand loads
  /// it, later expands reuse the cache.
  Future<void> toggleMolecule(String moleculeId) async {
    if (expandedMolecules.contains(moleculeId)) {
      expandedMolecules.remove(moleculeId);
      return;
    }
    expandedMolecules.add(moleculeId);
    if (!moleculeAtoms.containsKey(moleculeId)) {
      await _loadMoleculeAtoms(moleculeId);
    }
  }

  Future<void> _loadMoleculeAtoms(String moleculeId) async {
    loadingMolecules.add(moleculeId);
    try {
      final result = await _home.getAtoms(
        categoryId: moleculeId,
        page: 1,
        limit: 20,
      );
      if (result.success) {
        moleculeAtoms[moleculeId] = result.records;
      }
    } catch (error) {
      debugPrint('🏠 [HomeController] molecule atoms error: $error');
    } finally {
      loadingMolecules.remove(moleculeId);
    }
  }

  /// Socket atom events: keep every expanded molecule's inline list fresh.
  Future<void> refreshExpandedMolecules() async {
    for (final moleculeId in expandedMolecules.toList()) {
      await _loadMoleculeAtoms(moleculeId);
    }
  }
}
