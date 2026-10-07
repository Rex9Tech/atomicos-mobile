// test/modules/home/controllers/molecule_expand_test.dart
//
// Home's molecule accordion: expanding loads the molecule's atoms with the
// molecule filter, collapsing keeps the cache, and socket refreshes reload
// only what is expanded.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/services/category.service.dart';
import 'package:rexone_mobile/services/storage.service.dart';
import 'package:rexone_mobile/services/version.service.dart';

import '../../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHomeService fakeHome;
  late HomeController controller;

  AtomModel atom(String id, String title) => AtomModel(
    id: id,
    title: title,
    source: 'note',
    status: 'completed',
    createdAt: '2026-10-06T00:00:00Z',
    updatedAt: '2026-10-06T00:00:00Z',
  );

  setUp(() {
    Get.testMode = true;
    fakeHome = FakeHomeService();
    Get.put<VersionService>(FakeVersionService());
    Get.put<HomeService>(fakeHome);
    Get.put<CategoryService>(FakeCategoryService());
    Get.put<StorageService>(FakeStorageService());
    controller = Get.put(HomeController());
  });

  tearDown(Get.reset);

  test('expanding a molecule loads its atoms with the molecule filter',
      () async {
    fakeHome.pages.add([atom('a1', 'First'), atom('a2', 'Second')]);

    await controller.toggleMolecule('cat-1');

    expect(controller.expandedMolecules.contains('cat-1'), isTrue);
    expect(controller.moleculeAtoms['cat-1']?.length, 2);
    expect(fakeHome.requestedCategoryIds.contains('cat-1'), isTrue);
  });

  test('collapsing keeps the cache and re-expanding does not refetch',
      () async {
    fakeHome.pages.add([atom('a1', 'First')]);

    await controller.toggleMolecule('cat-1');
    await controller.toggleMolecule('cat-1'); // collapse
    expect(controller.expandedMolecules.contains('cat-1'), isFalse);
    expect(controller.moleculeAtoms.containsKey('cat-1'), isTrue);

    await controller.toggleMolecule('cat-1'); // re-expand (cached)
    final requests =
        fakeHome.requestedCategoryIds.where((id) => id == 'cat-1').length;
    expect(requests, 1);
  });

  test('socket refresh reloads only expanded molecules', () async {
    fakeHome.pages.add([atom('a1', 'First')]);
    await controller.toggleMolecule('cat-1');

    await controller.refreshExpandedMolecules();

    final requests =
        fakeHome.requestedCategoryIds.where((id) => id == 'cat-1').length;
    expect(requests, 2);
    expect(fakeHome.requestedCategoryIds.contains('cat-2'), isFalse);
  });

  test('onHomeVisible refreshes molecules and expanded atoms', () async {
    fakeHome.pages.add([atom('a1', 'First')]);
    await controller.toggleMolecule('cat-1');

    await controller.onHomeVisible();

    final requests =
        fakeHome.requestedCategoryIds.where((id) => id == 'cat-1').length;
    expect(requests, 2);
  });
}
