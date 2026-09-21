// test/modules/calendar/calendar_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/calendar/calendar.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCalendarService fakeService;
  late CalendarController controller;

  CalendarEventModel event({
    required String id,
    required String title,
    required DateTime start,
    DateTime? end,
  }) {
    return CalendarEventModel(
      id: id,
      title: title,
      startAt: start.toUtc().toIso8601String(),
      endAt: (end ?? start.add(const Duration(hours: 1)))
          .toUtc()
          .toIso8601String(),
      status: 'scheduled',
      createdAt: '',
      updatedAt: '',
    );
  }

  setUp(() {
    Get.testMode = true;
    fakeService = FakeCalendarService();
    Get.put<CalendarService>(fakeService);
    controller = Get.put(CalendarController());
  });

  tearDown(() {
    Get.reset();
  });

  group('CalendarController - grid math', () {
    test(
      'daysInMonth and Monday-first leading blanks are real-month correct',
      () {
        controller.viewMonth.value = DateTime(
          2026,
          9,
          1,
        ); // Sep 1 2026 = Tuesday
        expect(controller.daysInMonth, equals(30));
        expect(controller.leadingBlanks, equals(1));

        controller.viewMonth.value = DateTime(
          2026,
          11,
          1,
        ); // Nov 1 2026 = Sunday
        expect(controller.daysInMonth, equals(30));
        expect(controller.leadingBlanks, equals(6));

        controller.viewMonth.value = DateTime(2026, 2, 1);
        expect(controller.daysInMonth, equals(28));
      },
    );

    test('month navigation steps forward and back through the year', () {
      final original = controller.viewMonth.value;

      controller.goToNextMonth();
      expect(
        controller.viewMonth.value.month,
        equals(original.month == 12 ? 1 : original.month + 1),
      );
      expect(controller.selectedDay.value, equals(1));

      controller.goToPreviousMonth();
      expect(controller.viewMonth.value.month, equals(original.month));
      expect(controller.viewMonth.value.year, equals(original.year));
    });
  });

  group('CalendarController - range filtering', () {
    test('Month range lists every event in the shown month', () async {
      fakeService.eventsResponse = [
        event(id: 'e1', title: 'Meeting', start: DateTime(2026, 9, 21, 10)),
        event(id: 'e2', title: 'Other month', start: DateTime(2026, 10, 2, 9)),
      ];
      await controller.loadEvents();

      controller.viewMonth.value = DateTime(2026, 9, 1);
      controller.selectRange('Month');

      expect(controller.filteredEvents.length, equals(1));
      expect(controller.filteredEvents.first.id, equals('e1'));
    });

    test('Day range filters to the selected day', () async {
      fakeService.eventsResponse = [
        event(
          id: 'e21',
          title: 'Mon meeting',
          start: DateTime(2026, 9, 21, 10),
        ),
        event(
          id: 'e22',
          title: 'Tue meeting',
          start: DateTime(2026, 9, 22, 11),
        ),
      ];
      await controller.loadEvents();

      controller.viewMonth.value = DateTime(2026, 9, 1);
      controller.selectRange('Day');

      controller.selectDay(21);
      expect(controller.filteredEvents.map((e) => e.id), equals(['e21']));

      controller.selectDay(22);
      expect(controller.filteredEvents.map((e) => e.id), equals(['e22']));
    });

    test('Week range covers the whole Monday–Sunday week', () async {
      fakeService.eventsResponse = [
        // Sep 21 2026 is a Monday; the week spans Sep 21–27.
        event(
          id: 'prev_sun',
          title: 'Prev week',
          start: DateTime(2026, 9, 20, 9),
        ),
        event(id: 'thu', title: 'This week', start: DateTime(2026, 9, 24, 15)),
        event(
          id: 'next_mon',
          title: 'Next week',
          start: DateTime(2026, 9, 28, 9),
        ),
      ];
      await controller.loadEvents();

      controller.viewMonth.value = DateTime(2026, 9, 1);
      controller.selectDay(24);
      controller.selectRange('Week');

      expect(controller.filteredEvents.map((e) => e.id), equals(['thu']));
    });

    test('hasEventOnDay flags meeting days inside the shown month', () async {
      fakeService.eventsResponse = [
        event(id: 'e1', title: 'Meeting', start: DateTime(2026, 9, 21, 10)),
      ];
      await controller.loadEvents();

      controller.viewMonth.value = DateTime(2026, 9, 1);
      expect(controller.hasEventOnDay(21), isTrue);
      expect(controller.hasEventOnDay(22), isFalse);

      controller.viewMonth.value = DateTime(2026, 10, 1);
      expect(controller.hasEventOnDay(21), isFalse);
    });
  });

  group('CalendarController - event helpers', () {
    test('eventTime and eventTimeRange render start and end clocks', () {
      final meeting = event(
        id: 'e1',
        title: 'Meeting',
        start: DateTime(2026, 9, 21, 14, 30),
        end: DateTime(2026, 9, 21, 15, 30),
      );

      expect(controller.eventTime(meeting), equals('14:30'));
      expect(controller.eventTimeRange(meeting), equals('14:30 – 15:30'));
    });

    test('eventTimeRange falls back to the start time without an end', () {
      final solo = CalendarEventModel(
        id: 'e2',
        title: 'Solo',
        startAt: DateTime(2026, 9, 21, 9, 5).toUtc().toIso8601String(),
        status: 'scheduled',
        createdAt: '',
        updatedAt: '',
      );

      expect(controller.eventTimeRange(solo), equals('09:05'));
    });

    test('events sort chronologically inside a range', () async {
      fakeService.eventsResponse = [
        event(id: 'late', title: 'Late', start: DateTime(2026, 9, 21, 16)),
        event(id: 'early', title: 'Early', start: DateTime(2026, 9, 21, 8)),
      ];
      await controller.loadEvents();

      controller.viewMonth.value = DateTime(2026, 9, 1);
      controller.selectRange('Month');

      expect(
        controller.filteredEvents.map((e) => e.id),
        equals(['early', 'late']),
      );
    });
  });
}
