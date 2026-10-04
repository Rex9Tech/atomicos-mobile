// test/modules/molecule/molecule_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/home/data/models/atom.model.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/modules/molecule/molecule.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHomeService fakeHome;
  late MoleculeController controller;

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
    controller = MoleculeController(
      moleculeId: 'mol-1',
      moleculeName: 'Work',
    )..onInit();
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('reload loads page 1 filtered by this molecule and reports more pages', () async {
    fakeHome.pages.addAll([
      List.generate(20, (i) => atom('p1-$i')),
      List.generate(5, (i) => atom('p2-$i')),
    ]);

    await controller.reload();

    expect(controller.atoms.length, 20);
    expect(controller.hasMore.value, isTrue);
    expect(controller.hasError.value, isFalse);
    expect(fakeHome.requestedPages, [1]);
    // Every fetch is scoped to this molecule.
    expect(fakeHome.requestedCategoryIds, ['mol-1']);
  });

  test('loadMore appends the next page and exhausts pagination', () async {
    fakeHome.pages.addAll([
      List.generate(20, (i) => atom('p1-$i')),
      List.generate(5, (i) => atom('p2-$i')),
    ]);

    await controller.reload();
    await controller.loadMore();

    expect(controller.atoms.length, 25);
    expect(controller.atoms.last.id, 'p2-4');
    expect(controller.hasMore.value, isFalse);
    expect(controller.isLoadingMore.value, isFalse);
    expect(fakeHome.requestedPages, [1, 2]);
    expect(fakeHome.requestedCategoryIds.every((id) => id == 'mol-1'), isTrue);

    // Exhausted: another loadMore must not hit the network.
    await controller.loadMore();
    expect(fakeHome.requestedPages, [1, 2]);
  });

  test('loadMore keeps the list and retries after a failure', () async {
    fakeHome.pages.addAll([
      List.generate(20, (i) => atom('p1-$i')),
      List.generate(5, (i) => atom('p2-$i')),
    ]);

    await controller.reload();

    fakeHome.throwOnGetAtoms = true;
    await controller.loadMore();

    expect(controller.atoms.length, 20);
    expect(controller.hasMore.value, isTrue);
    expect(controller.isLoadingMore.value, isFalse);

    // Next scroll retries the same page.
    fakeHome.throwOnGetAtoms = false;
    await controller.loadMore();

    expect(controller.atoms.length, 25);
    expect(fakeHome.requestedPages, [1, 2, 2]);
  });

  test('a reload resets pagination to page 1', () async {
    fakeHome.pages.addAll([
      List.generate(20, (i) => atom('p1-$i')),
      List.generate(5, (i) => atom('p2-$i')),
    ]);

    await controller.reload();
    await controller.loadMore();
    expect(controller.atoms.length, 25);

    // A refresh starts over from page 1 — the previously appended page must
    // not duplicate rows.
    await controller.reload();

    expect(controller.atoms.length, 20);
    expect(controller.hasMore.value, isTrue);
    expect(fakeHome.requestedPages.last, 1);

    // ...and loadMore can append again from the fresh base.
    await controller.loadMore();
    expect(controller.atoms.length, 25);
  });

  test('an empty molecule settles into the empty state', () async {
    await controller.reload();

    expect(controller.atoms, isEmpty);
    expect(controller.isLoading.value, isFalse);
    expect(controller.hasError.value, isFalse);
    expect(controller.hasMore.value, isFalse);
  });

  test('a molecule without an id reports an error instead of fetching', () async {
    final empty = MoleculeController(moleculeId: '', moleculeName: 'Broken')
      ..onInit();

    await empty.reload();

    expect(empty.hasError.value, isTrue);
    expect(empty.isLoading.value, isFalse);
    expect(fakeHome.requestedPages, isEmpty);

    empty.onClose();
  });
}
