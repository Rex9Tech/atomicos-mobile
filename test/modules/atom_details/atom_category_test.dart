// test/modules/atom_details/atom_category_test.dart
//
// The details menu's "Set category" flow: the picker sends the chosen
// category id (or null to clear) through PUT /v1/atoms/:id and mirrors the
// response back into the page's atom.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/atom_details/controllers/atom_details.controller.dart';
import 'package:rexone_mobile/modules/calendar/services/calendar.service.dart';
import 'package:rexone_mobile/modules/home/data/models/atom.model.dart';
import 'package:rexone_mobile/modules/home/data/models/category.model.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/services/category.service.dart';
import 'package:rexone_mobile/services/media.service.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHomeService home;
  late FakeCategoryService categories;

  setUp(() {
    Get.testMode = true;
    home = FakeHomeService();
    categories = FakeCategoryService();
    Get.put<HomeService>(home);
    Get.put<MediaService>(FakeMediaService());
    Get.put<CalendarService>(FakeCalendarService());
    Get.put<CategoryService>(categories);
  });

  tearDown(Get.reset);

  AtomDetailsController controllerFor(AtomModel atom) {
    final controller = AtomDetailsController();
    controller.atomId.value = atom.id;
    controller.atom.value = atom;
    return controller;
  }

  test('picking a category sends its id and mirrors the response', () async {
    final controller = controllerFor(
      AtomModel.fromJson(const {'id': 'atom-1', 'title': 'One'}),
    );

    final ok = await controller.updateCategory('cat-work');

    expect(ok, isTrue);
    expect(home.requestedCategoryUpdates, ['cat-work']);
    expect(controller.atom.value?.categoryId, 'cat-work');
  });

  test('choosing "No category" clears it with an explicit null', () async {
    final controller = controllerFor(
      AtomModel.fromJson(const {
        'id': 'atom-2',
        'title': 'Two',
        'category_id': 'cat-old',
      }),
    );

    final ok = await controller.updateCategory(null);

    expect(ok, isTrue);
    expect(home.requestedCategoryUpdates, [null]);
    expect(controller.atom.value?.categoryId, isNull);
  });

  test('the current user\'s list resolves names by id', () {
    categories.categories.assignAll([
      const CategoryModel(id: 'cat-work', name: 'Work'),
      const CategoryModel(id: 'cat-ideas', name: 'Ideas'),
    ]);

    expect(categories.byId('cat-work')?.name, 'Work');
    expect(categories.byId('cat-foreign'), isNull);
    expect(categories.byId(null), isNull);
  });
}
