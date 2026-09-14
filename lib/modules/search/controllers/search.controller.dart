// lib/modules/search/controllers/search.controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';

import '../../home/data/models/atom.model.dart';
import '../../home/services/home.service.dart';

/// Drives the dedicated search screen: debounced query, category filter and
/// the result list (with its empty state).
class AtomSearchController extends GetxController {
  static const filters = <String>['All', 'AtomOS', 'New', 'Personal'];

  final HomeService _home = Get.find<HomeService>();

  final searchController = TextEditingController();
  final RxString query = ''.obs;
  final RxString selectedFilter = 'All'.obs;
  final RxList<AtomModel> results = <AtomModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  Timer? _debounce;

  /// True when the current query matched nothing.
  bool get isEmptyResult =>
      hasLoaded.value && !isLoading.value && results.isEmpty;

  @override
  void onInit() {
    super.onInit();
    // Fetch after the route's first frame: mutating Rx state while the page
    // is still building trips "markNeedsBuild() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) search();
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void onQueryChanged(String value) {
    query.value = value.trim();
    _debounce?.cancel();
    _debounce = Timer(Design.timers.debounce, search);
  }

  void clear() {
    if (searchController.text.isEmpty && query.value.isEmpty) return;
    searchController.clear();
    query.value = '';
    _debounce?.cancel();
    search();
  }

  void selectFilter(String value) {
    selectedFilter.value = value;
    search();
  }

  Future<void> search() async {
    isLoading.value = true;
    try {
      final result = await _home.getAtoms(
        limit: 20,
        search: query.value.isEmpty ? null : query.value,
        status: _statusForFilter(selectedFilter.value),
      );
      results.assignAll(
        _applyLocalFilter(result.records, selectedFilter.value),
      );
    } catch (error) {
      debugPrint('🔎 [AtomSearchController] search failed: $error');
      results.clear();
    } finally {
      hasLoaded.value = true;
      isLoading.value = false;
    }
  }

  String? _statusForFilter(String filter) =>
      filter.toLowerCase() == 'new' ? 'new' : null;

  List<AtomModel> _applyLocalFilter(List<AtomModel> source, String filter) {
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
