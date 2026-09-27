// test/controllers/pagy_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/controllers/pagy.controller.dart';
import 'package:rexone_mobile/models/models.dart';

class TestItem {
  final String id;
  final String title;

  const TestItem({required this.id, required this.title});
}

class TestPagyController extends GetxController with PagyControllerMixin<TestItem> {
  int fetchCallCount = 0;
  String? lastSearch;
  Map<String, dynamic>? lastFilters;
  int? lastPage;
  bool shouldFail = false;

  @override
  Future<PaginatedResponse<TestItem>> fetchPage({
    required int page,
    required int limit,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    fetchCallCount++;
    lastPage = page;
    lastSearch = search;
    lastFilters = filters;

    if (shouldFail) {
      return const PaginatedResponse<TestItem>(
        records: [],
        message: 'Server error occurred',
        statusCode: 500,
        success: false,
      );
    }

    final hasNext = page < 3;
    final records = List.generate(
      limit,
      (i) => TestItem(
        id: 'item_${(page - 1) * limit + i}',
        title: 'Item ${(page - 1) * limit + i} (search: $search)',
      ),
    );

    return PaginatedResponse<TestItem>(
      records: records,
      pagination: PaginationMeta(
        currentPage: page,
        totalPages: 3,
        totalCount: 30,
        limit: limit,
        nextPage: hasNext ? page + 1 : null,
        prevPage: page > 1 ? page - 1 : null,
      ),
      message: 'OK',
      statusCode: 200,
      success: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestPagyController controller;

  setUp(() {
    Get.testMode = true;
    controller = Get.put(TestPagyController());
  });

  tearDown(() {
    Get.reset();
  });

  group('PagyControllerMixin', () {
    test('refreshList populates items and pagination metadata', () async {
      expect(controller.items, isEmpty);
      expect(controller.pagination.value, isNull);

      await controller.refreshList();

      expect(controller.items.length, 10);
      expect(controller.pagination.value?.currentPage, 1);
      expect(controller.pagination.value?.totalCount, 30);
      expect(controller.hasMore, isTrue);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNull);
    });

    test('loadMore fetches subsequent pages and appends to items', () async {
      await controller.refreshList();
      expect(controller.items.length, 10);

      await controller.loadMore();
      expect(controller.items.length, 20);
      expect(controller.pagination.value?.currentPage, 2);
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.items.length, 30);
      expect(controller.pagination.value?.currentPage, 3);
      expect(controller.hasMore, isFalse);

      // Should not load more when hasMore is false
      final countBefore = controller.fetchCallCount;
      await controller.loadMore();
      expect(controller.fetchCallCount, countBefore);
    });

    test('setFilter sets active filter and reloads from page 1', () async {
      await controller.refreshList();

      controller.setFilter('category', 'premium');

      // Wait for async refresh
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.activeFilters['category'], 'premium');
      expect(controller.lastFilters?['category'], 'premium');

      controller.setFilter('category', null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.activeFilters.containsKey('category'), isFalse);
    });

    test('onSearchChanged debounces and reloads with query', () async {
      controller.onSearchChanged(
        'flutter',
        debounceDuration: const Duration(milliseconds: 50),
      );

      // Immediately before debounce fires
      expect(controller.searchQuery.value, isEmpty);

      // After debounce duration
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(controller.searchQuery.value, 'flutter');
      expect(controller.lastSearch, 'flutter');
    });

    test('resetFilters clears search and filter map', () async {
      controller.setFilter('status', 'active');
      controller.searchQuery.value = 'query';

      controller.resetFilters();

      expect(controller.searchQuery.value, isEmpty);
      expect(controller.activeFilters, isEmpty);
    });

    test('captures server errors into errorMessage', () async {
      controller.shouldFail = true;

      await controller.refreshList();

      expect(controller.items, isEmpty);
      expect(controller.errorMessage.value, 'Server error occurred');
      expect(controller.isLoading.value, isFalse);
    });
  });
}
