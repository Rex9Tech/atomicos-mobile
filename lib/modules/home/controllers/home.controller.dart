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
  final CategoryService _categories = Get.find<CategoryService>();

  final RxString selectedFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;

  final RxList<AtomModel> atoms = <AtomModel>[].obs;
  final RxBool isLoadingAtoms = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreAtoms = true.obs;
  final RxBool hasAtomsError = false.obs;
  final searchController = TextEditingController();
  Timer? _searchDebounce;

  int _currentPage = 1;
  static const int _pageSize = 20;
  static const int _loadAttempts = 4;
  static const Duration _retryBackoff = Duration(milliseconds: 900);

  @override
  void onInit() {
    super.onInit();
    if (Get.testMode) return;
    // Deferred one frame: the controller is constructed lazily while the
    // first HomePage build is still running, and starting the request (plus
    // its global-loading Rx writes) inside a build phase trips flutter's
    // markNeedsBuild guard. Post-frame keeps the whole load lifecycle
    // outside the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAtoms();
      // Dynamic chips: admin-managed categories, refreshed silently.
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
          page: 1,
          limit: _pageSize,
          search: resolvedSearch,
          categoryId: _categoryIdFor(resolvedFilter),
        );
        atoms.assignAll(result.records);
        _currentPage = 1;
        hasMoreAtoms.value =
            result.pagination?.hasNextPage ??
            (result.records.length >= _pageSize);
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

  /// Appends the next page of atoms — driven by infinite scroll on Home.
  ///
  /// Never touches the global loading overlay and never blanks the list: a
  /// failed page simply leaves [hasMoreAtoms] as it was, so the next scroll
  /// retries.
  Future<void> loadMore() async {
    if (isLoadingAtoms.value || isLoadingMore.value || !hasMoreAtoms.value) {
      return;
    }

    isLoadingMore.value = true;
    final nextPage = _currentPage + 1;
    final resolvedFilter = selectedFilter.value;

    try {
      final result = await _home.getAtoms(
        page: nextPage,
        limit: _pageSize,
        search: searchQuery.value,
        categoryId: _categoryIdFor(resolvedFilter),
      );

      // Guard against a refresh that landed while this page was in flight.
      if (nextPage == _currentPage + 1) {
        atoms.addAll(result.records);
        _currentPage = nextPage;
      }
      hasMoreAtoms.value =
          result.pagination?.hasNextPage ??
          (result.records.length >= _pageSize);
    } catch (error) {
      debugPrint('HomeController.loadMore page $nextPage failed: $error');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void selectFilter(String value) {
    if (selectedFilter.value == value) return;
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

  /// 'all' → no category filter; anything else is a category id.
  String? _categoryIdFor(String filter) =>
      filter == 'all' || filter.isEmpty ? null : filter;
}
