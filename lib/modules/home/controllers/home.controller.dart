import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rexone_mobile/config/config.dart';
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
  final meetingLinkController = TextEditingController();
  Timer? _searchDebounce;

  bool get isLoading => previewState.value == 'loading';
  bool get isEmpty => previewState.value == 'empty';
  bool get isError => previewState.value == 'error';

  @override
  void onInit() {
    super.onInit();
    if (Get.testMode) return;
    reportUserVersion();
    loadAtoms();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    meetingLinkController.dispose();
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

  Future<void> loadAtoms({String? search, String? filter}) async {
    final resolvedSearch = search ?? searchQuery.value;
    final resolvedFilter = filter ?? selectedFilter.value;
    isLoadingAtoms.value = true;
    hasAtomsError.value = false;
    try {
      final result = await _home.getAtoms(
        limit: 20,
        search: resolvedSearch,
        status: _statusForFilter(resolvedFilter),
      );
      atoms.assignAll(
        _applyLocalFilter(result.records, filter: resolvedFilter),
      );
    } catch (error) {
      debugPrint('HomeController.loadAtoms error: $error');
      hasAtomsError.value = true;
    } finally {
      isLoadingAtoms.value = false;
    }
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
