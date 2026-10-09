// test/modules/atom_details/atom_meeting_date_test.dart
//
// The details meeting-date chip: dates save on the ATOM (server) — never the
// device calendar — and clearing sends an explicit null.
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

  AtomDetailsController controllerFor(AtomModel atom) {
    final controller = AtomDetailsController();
    controller.atomId.value = atom.id;
    controller.atom.value = atom;
    return controller;
  }

  test('saving a meeting date persists it on the atom', () async {
    final controller = controllerFor(
      AtomModel.fromJson(const {'id': 'atom-1', 'title': 'One'}),
    );

    final ok = await controller.saveMeetingDate(
      DateTime.utc(2026, 10, 8, 9, 30),
    );

    expect(ok, isTrue);
    expect(home.requestedMeetingDates.length, 1);
    expect(home.requestedMeetingDates.first, isNotNull);
    expect(home.requestedMeetingDates.first, contains('2026-10-08'));
    expect(controller.atom.value?.meetingAt, isNotNull);
    expect(controller.meetingAt.value, isNotNull);
  });

  test('clearing sends an explicit null and falls back to the atom date',
      () async {
    final controller = controllerFor(
      AtomModel.fromJson(const {
        'id': 'atom-2',
        'title': 'Two',
        'meeting_at': '2026-10-08T09:30:00Z',
        'created_at': '2026-10-01T08:00:00Z',
      }),
    );

    controller.resolveMeetingDate();
    expect(controller.meetingAt.value, isNotNull);

    final ok = await controller.clearMeetingDate();

    expect(ok, isTrue);
    expect(home.requestedMeetingDates, [null]);
    // The chip falls back to the atom's own creation date.
    expect(controller.meetingAt.value, isNotNull);
    expect(controller.atom.value?.meetingAt, isNull);
  });
}
