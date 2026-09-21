// test/modules/home/home_pagination_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/home/controllers/home.controller.dart';
import 'package:rexone_mobile/modules/home/data/models/atom.model.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/services/category.service.dart';
import 'package:rexone_mobile/services/version.service.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHomeService fakeHome;
  late HomeController controller;

  AtomModel atom(String id) => AtomModel(
    id: id,
    title: 'Atom $id',
    source: 'note',
    status: 'completed',
    createdAt: '2026-09-01T00:00:00Z',
    updatedAt: '2026-09-01T00:00:00Z',
  );

  setUp(() {
    Get.testMode = true;
    fakeHome = FakeHomeService();
    Get.put<HomeService>(fakeHome);
    Get.put<VersionService>(FakeVersionService());
    Get.put<CategoryService>(FakeCategoryService());
    controller = HomeController();
  });

  tearDown(Get.reset);

  test('loadAtoms loads page 1 and reports more pages', () async {
    fakeHome.pages.addAll([
      List.generate(20, (i) => atom('p1-$i')),
      List.generate(5, (i) => atom('p2-$i')),
    ]);

    await controller.loadAtoms();

    expect(controller.atoms.length, 20);
    expect(controller.hasMoreAtoms.value, isTrue);
    expect(fakeHome.requestedPages, [1]);
  });

  test('loadMore appends the next page and exhausts pagination', () async {
    fakeHome.pages.addAll([
      List.generate(20, (i) => atom('p1-$i')),
      List.generate(5, (i) => atom('p2-$i')),
    ]);

    await controller.loadAtoms();
    await controller.loadMore();

    expect(controller.atoms.length, 25);
    expect(controller.atoms.last.id, 'p2-4');
    expect(controller.hasMoreAtoms.value, isFalse);
    expect(controller.isLoadingMore.value, isFalse);
    expect(fakeHome.requestedPages, [1, 2]);

    // Exhausted: another loadMore must not hit the network.
    await controller.loadMore();
    expect(fakeHome.requestedPages, [1, 2]);
  });

  test('loadMore keeps the list and retries after a failure', () async {
    fakeHome.pages.addAll([
      List.generate(20, (i) => atom('p1-$i')),
      List.generate(5, (i) => atom('p2-$i')),
    ]);

    await controller.loadAtoms();

    fakeHome.throwOnGetAtoms = true;
    await controller.loadMore();

    expect(controller.atoms.length, 20);
    expect(controller.hasMoreAtoms.value, isTrue);
    expect(controller.isLoadingMore.value, isFalse);

    // Next scroll retries the same page.
    fakeHome.throwOnGetAtoms = false;
    await controller.loadMore();

    expect(controller.atoms.length, 25);
    expect(fakeHome.requestedPages, [1, 2, 2]);
  });

  test('a refreshed loadAtoms resets pagination to page 1', () async {
    fakeHome.pages.addAll([
      List.generate(20, (i) => atom('p1-$i')),
      List.generate(5, (i) => atom('p2-$i')),
    ]);

    await controller.loadAtoms();
    await controller.loadMore();
    expect(controller.atoms.length, 25);

    // A filter/search refresh starts over from page 1 — the previously
    // appended page must not duplicate rows.
    await controller.loadAtoms();

    expect(controller.atoms.length, 20);
    expect(controller.hasMoreAtoms.value, isTrue);
    expect(fakeHome.requestedPages.last, 1);

    // ...and loadMore can append again from the fresh base.
    await controller.loadMore();
    expect(controller.atoms.length, 25);
  });
}
