// test/modules/atom_details/atom_delete_test.dart
//
// Deleting an atom from the details screen: the controller sends
// DELETE /v1/atoms/:id, drops the atom's device-calendar event when one is
// linked, keeps the UI on the page when the server refuses, and reports
// success so the page can leave + refresh the list behind it.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/atom_details/controllers/atom_details.controller.dart';
import 'package:rexone_mobile/modules/home/data/models/atom.model.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/services/category.service.dart';
import 'package:rexone_mobile/services/media.service.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHomeService home;

  setUp(() {
    Get.testMode = true;
    home = FakeHomeService();
    Get.put<HomeService>(home);
    Get.put<MediaService>(FakeMediaService());
    Get.put<CategoryService>(FakeCategoryService());
  });

  tearDown(Get.reset);

  AtomDetailsController controllerFor(String id, String title) {
    final controller = AtomDetailsController();
    controller.atomId.value = id;
    controller.atom.value = AtomModel.fromJson({'id': id, 'title': title});
    return controller;
  }

  test('deleteAtom soft-deletes and reports success', () async {
    final controller = controllerFor('atom-del', 'Trash me');

    final ok = await controller.deleteAtom();

    expect(ok, isTrue);
    expect(home.deletedAtomIds, ['atom-del']);
  });

  test('deleteAtom failure keeps the atom and reports false', () async {
    home.throwOnDelete = true;
    final controller = controllerFor('atom-keep', 'Keep me');

    final ok = await controller.deleteAtom();

    expect(ok, isFalse);
    expect(home.deletedAtomIds, isEmpty);
  });

  test('deleteAtom does nothing for an empty atom id', () async {
    final controller = AtomDetailsController();

    final ok = await controller.deleteAtom();

    expect(ok, isFalse);
    expect(home.deletedAtomIds, isEmpty);
  });
}
