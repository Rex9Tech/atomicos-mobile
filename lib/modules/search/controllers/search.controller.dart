// lib/modules/search/controllers/search.controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../home/data/models/atom.model.dart';
import '../../home/services/home.service.dart';

/// Drives the dedicated search screen: debounced query, category filter and
/// the result list (with its empty state).
class AtomSearchController extends GetxController {
  final HomeService _home = Get.find<HomeService>();
  final CategoryService _categories = Get.find<CategoryService>();

  final searchController = TextEditingController();
  final RxString query = ''.obs;

  /// 'all' → no category filter; anything else is a category id.
  final RxString selectedFilter = 'all'.obs;
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
    if (Get.testMode) return;
    // Fetch after the route's first frame: mutating Rx state while the page
    // is still building trips "markNeedsBuild() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      search();
      // Dynamic chips: the current user's own categories.
      _categories.refresh();
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
    if (selectedFilter.value == value) return;
    selectedFilter.value = value;
    search();
  }

  Future<void> search() async {
    isLoading.value = true;
    try {
      final result = await _home.getAtoms(
        limit: 20,
        search: query.value.isEmpty ? null : query.value,
        categoryId: _categoryIdFor(selectedFilter.value),
      );
      results.assignAll(result.records);
    } catch (error) {
      debugPrint('🔎 [AtomSearchController] search failed: $error');
      results.clear();
    } finally {
      hasLoaded.value = true;
      isLoading.value = false;
    }
  }

  /// 'all' → no category filter; anything else is a category id.
  String? _categoryIdFor(String filter) =>
      filter == 'all' || filter.isEmpty ? null : filter;
}
