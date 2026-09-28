// lib/controllers/pagy.mixin.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/models/models.dart';

/// Reusable controller mixin for infinite scroll pagination following Core's Pagy contract.
///
/// Can be mixed into any [GetxController] (e.g. `PaymentController`, `PlaylistController`).
/// Automatically manages:
/// - Reactive item collection ([items])
/// - Pagination metadata ([pagination])
/// - Initial loading ([isLoading]), loading more ([isLoadingMore]), and pull-to-refresh ([isRefreshing])
/// - Debounced search queries ([searchQuery])
/// - Active filters map ([activeFilters])
/// - Errors ([errorMessage])
mixin PagyControllerMixin<T> on GetxController {
  /// The reactive list of currently loaded records.
  final RxList<T> items = <T>[].obs;

  /// Pagy metadata returned from the backend envelope (`meta.pagination`).
  final Rxn<PaginationMeta> pagination = Rxn<PaginationMeta>();

  /// Initial loading state when fetching page 1 and [items] is empty.
  final RxBool isLoading = false.obs;

  /// Loading state when appending subsequent pages near the bottom of the list.
  final RxBool isLoadingMore = false.obs;

  /// Loading state during pull-to-refresh actions.
  final RxBool isRefreshing = false.obs;

  /// Error message if the fetch failed, or null when successful.
  final RxnString errorMessage = RxnString();

  /// Current search query string.
  final RxString searchQuery = ''.obs;

  /// Map of currently applied filter keys and values.
  final RxMap<String, dynamic> activeFilters = <String, dynamic>{}.obs;

  /// Internal debounce timer for live search keystrokes.
  Timer? _searchDebounceTimer;

  /// Default page size requested per batch. Defaults to 10.
  int get pageLimit => 10;

  /// Whether there are more pages available according to Pagy's `next_page`.
  bool get hasMore => pagination.value?.hasNextPage ?? false;

  /// Total count of items on the server from Pagy's `total_count`.
  int get totalCount => pagination.value?.totalCount ?? items.length;

  /// Current 1-indexed page from Pagy.
  int get currentPage => pagination.value?.currentPage ?? 1;

  /// Total pages from Pagy.
  int get totalPages => pagination.value?.totalPages ?? 1;

  /// Abstract contract method that each implementing controller MUST provide.
  ///
  /// Fetches a single page matching [page], [limit], optional [search], and [filters].
  @protected
  Future<PaginatedResponse<T>> fetchPage({
    required int page,
    required int limit,
    String? search,
    Map<String, dynamic>? filters,
  });

  /// Refreshes the list from page 1.
  ///
  /// Set [isPullToRefresh] to true when invoked from a [RefreshIndicator] to update
  /// [isRefreshing] rather than [isLoading].
  Future<void> refreshList({bool isPullToRefresh = false}) async {
    if (isLoading.value || isLoadingMore.value) return;

    if (isPullToRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = null;

    try {
      final query = searchQuery.value.trim();
      final effectiveSearch = query.isEmpty ? null : query;
      final effectiveFilters = activeFilters.isEmpty
          ? null
          : Map<String, dynamic>.from(activeFilters);

      final response = await fetchPage(
        page: 1,
        limit: pageLimit,
        search: effectiveSearch,
        filters: effectiveFilters,
      );

      if (response.success) {
        items.assignAll(response.records);
        pagination.value = response.pagination;
      } else {
        errorMessage.value = response.message;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '❌ [PagyControllerMixin] refreshList error: $error\n$stackTrace',
      );
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Fetches the next page of records and appends them to [items].
  ///
  /// Safely guards against concurrent fetches and stops when [hasMore] is false.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;

    final nextPage = pagination.value?.nextPage;
    if (nextPage == null) return;

    isLoadingMore.value = true;
    try {
      final query = searchQuery.value.trim();
      final effectiveSearch = query.isEmpty ? null : query;
      final effectiveFilters = activeFilters.isEmpty
          ? null
          : Map<String, dynamic>.from(activeFilters);

      final response = await fetchPage(
        page: nextPage,
        limit: pageLimit,
        search: effectiveSearch,
        filters: effectiveFilters,
      );

      if (response.success) {
        items.addAll(response.records);
        pagination.value = response.pagination;
      }
    } catch (error, stackTrace) {
      debugPrint('❌ [PagyControllerMixin] loadMore error: $error\n$stackTrace');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Updates the search query with built-in debouncing (default 350ms).
  ///
  /// When debounced duration elapses, automatically triggers [refreshList].
  void onSearchChanged(
    String query, {
    Duration debounceDuration = const Duration(milliseconds: 350),
  }) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(debounceDuration, () {
      if (searchQuery.value != query) {
        searchQuery.value = query;
        refreshList();
      }
    });
  }

  /// Applies or clears a specific filter key and refreshes the list from page 1.
  void setFilter(String key, dynamic value) {
    if (value == null) {
      activeFilters.remove(key);
    } else {
      activeFilters[key] = value;
    }
    refreshList();
  }

  /// Clears all active filters and the search query, then reloads page 1.
  void resetFilters() {
    searchQuery.value = '';
    activeFilters.clear();
    refreshList();
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    super.onClose();
  }
}

/// Generic base controller implementing [PagyControllerMixin].
/// Useful when a standalone paginated controller is preferred over a mixin.
abstract class PagyController<T> extends GetxController
    with PagyControllerMixin<T> {
  @override
  void onReady() {
    super.onReady();
    refreshList();
  }
}
