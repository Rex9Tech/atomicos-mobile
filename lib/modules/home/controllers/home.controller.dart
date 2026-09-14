import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rexone_mobile/config/config.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/services/services.dart';

import '../data/models/models.dart';
import '../services/home.service.dart';

class HomeController extends GetxController {
  final VersionService _version = Get.find<VersionService>();
  final HomeService _home = Get.find<HomeService>();

  final RxString selectedFilter = 'All'.obs;
  final RxString previewState = 'content'.obs;
  final RxString searchQuery = ''.obs;

  final RxList<AtomModel> atoms = <AtomModel>[].obs;
  final RxBool isLoadingAtoms = false.obs;
  final RxBool hasAtomsError = false.obs;
  final searchController = TextEditingController();
  Timer? _searchDebounce;

  bool get isLoading => previewState.value == 'loading';
  bool get isEmpty => previewState.value == 'empty';
  bool get isError => previewState.value == 'error';

  static const int _loadAttempts = 4;
  static const Duration _retryBackoff = Duration(milliseconds: 900);

  @override
  void onInit() {
    super.onInit();
    if (Get.testMode) return;
    loadAtoms();
    // Best-effort telemetry — staggered so it doesn't compete for the first
    // socket while the workspace request is still in flight.
    Future<void>.delayed(const Duration(seconds: 3), reportUserVersion);
    // Ask for notification access on entry: the background-recording
    // notification (with its Pause/Stop controls) depends on it.
    Future<void>.delayed(const Duration(milliseconds: 900), _promptNotifications);
  }

  /// One-time-per-launch prompt for notification permission. Skipped when it
  /// is already granted, so users who said yes are never nagged.
  Future<void> _promptNotifications() async {
    final permissions = Get.find<PermissionService>();
    if (permissions.notificationPromptShown) return;
    permissions.notificationPromptShown = true;

    if (await permissions.isNotificationAllowed()) return;

    final context = Get.context;
    if (context == null || !context.mounted) return;

    final enable = await AppDialog.confirm(
      context: context,
      title: AppLocales.permission.notificationTitle.tr,
      message: AppLocales.permission.notificationMessage.tr,
      confirmLabel: AppLocales.permission.notificationEnable.tr,
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
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> reportUserVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.isNotEmpty
          ? info.version
          : AppConfig.appVersion;
      final versionCode = int.tryParse(info.buildNumber) ?? 0;
      await _version.reportUserVersion(
        version: version,
        versionCode: versionCode,
      );
    } catch (error) {
      debugPrint('Error: $error');
    }
  }

  /// Loads the workspace atoms.
  ///
  /// The first request after a cold start can fail while the device network is
  /// still coming up, so transient failures are retried silently before the
  /// error state is surfaced — and already-loaded atoms are never discarded.
  Future<void> loadAtoms({String? search, String? filter}) async {
    final resolvedSearch = search ?? searchQuery.value;
    final resolvedFilter = filter ?? selectedFilter.value;
    isLoadingAtoms.value = true;
    hasAtomsError.value = false;

    for (var attempt = 1; attempt <= _loadAttempts; attempt++) {
      try {
        final result = await _home.getAtoms(
          limit: 20,
          search: resolvedSearch,
          status: _statusForFilter(resolvedFilter),
        );
        atoms.assignAll(
          _applyLocalFilter(result.records, filter: resolvedFilter),
        );
        hasAtomsError.value = false;
        isLoadingAtoms.value = false;
        return;
      } catch (error) {
        debugPrint(
          'HomeController.loadAtoms attempt $attempt/$_loadAttempts failed: $error',
        );
        if (attempt < _loadAttempts) {
          await Future<void>.delayed(_retryBackoff * attempt);
          continue;
        }
        hasAtomsError.value = true;
      }
    }

    isLoadingAtoms.value = false;
  }

  void selectFilter(String value) {
    selectedFilter.value = value;
    loadAtoms();
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(Design.timers.debounce, loadAtoms);
  }

  void clearSearch() {
    if (searchQuery.value.isEmpty && searchController.text.isEmpty) return;
    searchController.clear();
    searchQuery.value = '';
    _searchDebounce?.cancel();
    loadAtoms(search: '');
  }

  void setPreviewState(String value) {
    previewState.value = value;
  }

  String? _statusForFilter(String filter) {
    switch (filter.toLowerCase()) {
      case 'new':
        return 'new';
      default:
        return null;
    }
  }

  List<AtomModel> _applyLocalFilter(
    List<AtomModel> source, {
    required String filter,
  }) {
    switch (filter.toLowerCase()) {
      case 'atomos':
        return source
            .where((atom) => atom.source.toLowerCase().contains('atom'))
            .toList();
      case 'personal':
        return source.where((atom) {
          final haystack = [
            atom.source,
            atom.title,
            atom.status,
            atom.note ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains('personal');
        }).toList();
      default:
        return source;
    }
  }
}
