// test/modules/search/search_filter_test.dart
//
// The search screen's filter is the CURRENT USER's own category list — 'All'
// plus live CategoryService entries — and selecting one filters the atom
// query by `category_id`. (It used to be a hardcoded All/AtomOS/New/Personal
// list with string-matching "filtering".)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_translations.dart';
import 'package:rexone_mobile/modules/home/data/models/atom.model.dart';
import 'package:rexone_mobile/modules/home/data/models/category.model.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/modules/search/search.dart';
import 'package:rexone_mobile/services/category.service.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHomeService home;
  late FakeCategoryService categories;

  setUp(() {
    Get.testMode = true;
    // Re-registered per test: `Get.reset()` in tearDown drops translations.
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en');
    home = FakeHomeService();
    categories = FakeCategoryService();
    home.pages.add([
      AtomModel.fromJson(const {'id': 'a1', 'title': 'one'}),
      AtomModel.fromJson(const {'id': 'a2', 'title': 'two'}),
    ]);
    Get.put<HomeService>(home);
    Get.put<CategoryService>(categories);
  });

  tearDown(Get.reset);

  group('AtomSearchController filters', () {
    test("defaults to 'all' and sends no category filter", () async {
      final controller = AtomSearchController();

      await controller.search();

      expect(controller.selectedFilter.value, 'all');
      expect(home.requestedCategoryIds, [null]);
      expect(controller.results, hasLength(2));
    });

    test('selecting a category filters the query by its id', () async {
      final controller = AtomSearchController();

      controller.selectFilter('cat-work');
      await Future<void>.delayed(Duration.zero);

      expect(controller.selectedFilter.value, 'cat-work');
      expect(home.requestedCategoryIds.last, 'cat-work');

      // Re-selecting the same chip must not refetch.
      final calls = home.requestedCategoryIds.length;
      controller.selectFilter('cat-work');
      await Future<void>.delayed(Duration.zero);
      expect(home.requestedCategoryIds.length, calls);
    });
  });

  testWidgets('chips render All + the live categories, never the old mocks', (
    tester,
  ) async {
    categories.categories.assignAll([
      const CategoryModel(id: 'c1', name: 'Work'),
      const CategoryModel(id: 'c2', name: 'Ideas'),
    ]);
    Get.put(AtomSearchController());

    await tester.pumpWidget(
      MaterialApp(theme: Design.theme.light, home: const SearchPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Ideas'), findsOneWidget);

    // The hardcoded filter set must be gone for good.
    expect(find.text('AtomOS'), findsNothing);
    expect(find.text('Personal'), findsNothing);
    expect(find.text('New'), findsNothing);

    // Tapping a category chip drives the category_id filter.
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    expect(home.requestedCategoryIds.last, 'c1');
  });
}
