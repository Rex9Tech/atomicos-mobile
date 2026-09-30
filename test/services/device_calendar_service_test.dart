// test/services/device_calendar_service_test.dart
//
// The device-calendar sync workflow: meetings are written through the native
// CalendarContract bridge (mocked here), one event per atom, kept in sync on
// later edits and removable — with the atom→event link persisted locally.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/services/device_calendar.service.dart';
import 'package:rexone_mobile/services/storage.service.dart';

import '../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorageService storage;
  late DeviceCalendarService service;

  // Controllable fake of the native bridge.
  bool permissionGranted = true;
  List<Map<String, Object?>> calendars = [];
  final List<MethodCall> calls = [];
  String? nextEventId;

  setUp(() {
    Get.testMode = true;
    storage = FakeStorageService();
    Get.put<StorageService>(storage);
    service = DeviceCalendarService();
    service.debugSupportedOverride = true;
    Get.put<DeviceCalendarService>(service);

    permissionGranted = true;
    nextEventId = 'evt-100';
    calendars = [
      {
        'id': '1',
        'name': 'Personal',
        'accountName': 'me@gmail.com',
        'isReadOnly': false,
      },
      {
        'id': '2',
        'name': 'Holidays',
        'accountName': 'me@gmail.com',
        'isReadOnly': true,
      },
    ];
    calls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceCalendarChannel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'hasPermissions':
        case 'requestPermissions':
          return permissionGranted;
        case 'listCalendars':
          return calendars;
        case 'createOrUpdateEvent':
          return nextEventId;
        case 'deleteEvent':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceCalendarChannel, null);
    Get.reset();
  });

  test('sync creates the event, persists the link, remembers the calendar',
      () async {
    final start = DateTime(2026, 10, 5, 14, 30);

    final result = await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: start,
    );

    expect(result, CalendarSyncResult.synced);
    final link = service.linkFor('atom-1');
    expect(link, isNotNull);
    expect(link!.eventId, 'evt-100');
    expect(link.calendarId, '1');
    expect(link.date, start);

    final upsert = calls.lastWhere((c) => c.method == 'createOrUpdateEvent');
    final args = Map<String, Object?>.from(upsert.arguments as Map);
    expect(args['calendarId'], '1');
    expect(args['eventId'], isNull, reason: 'first sync creates a new event');
    expect(args['startMillis'], start.millisecondsSinceEpoch);
    expect(args['reminderMinutes'], 10);

    // The first writable calendar became the persisted target.
    expect(storage.getCalendarTarget()?['id'], '1');
    expect(service.targetCalendar?.name, 'Personal');
  });

  test('re-sync updates the SAME event instead of creating another',
      () async {
    await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: DateTime(2026, 10, 5, 14),
    );
    await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: DateTime(2026, 10, 5, 16),
    );

    final upserts =
        calls.where((c) => c.method == 'createOrUpdateEvent').toList();
    expect(upserts.length, 2);
    expect(
      Map<String, Object?>.from(upserts.last.arguments as Map)['eventId'],
      'evt-100',
      reason: 'the update must target the existing event',
    );
    expect(service.linkFor('atom-1')?.date, DateTime(2026, 10, 5, 16));
  });

  test('remove deletes the event and clears the link', () async {
    await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: DateTime(2026, 10, 5, 14),
    );

    final removed = await service.removeMeeting('atom-1');

    expect(removed, isTrue);
    expect(service.linkFor('atom-1'), isNull);
    final deletes = calls.where((c) => c.method == 'deleteEvent').toList();
    expect(deletes, isNotEmpty);
    expect(
      Map<String, Object?>.from(deletes.last.arguments as Map)['eventId'],
      'evt-100',
    );
  });

  test('permission refusal surfaces permissionDenied and writes nothing',
      () async {
    permissionGranted = false;

    final result = await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: DateTime(2026, 10, 5, 14),
    );

    expect(result, CalendarSyncResult.permissionDenied);
    expect(calls.any((c) => c.method == 'createOrUpdateEvent'), isFalse);
    expect(service.linkFor('atom-1'), isNull);
  });

  test('no writable calendar surfaces needCalendar', () async {
    calendars = [
      {
        'id': '2',
        'name': 'Holidays',
        'accountName': '',
        'isReadOnly': true,
      },
    ];

    final result = await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: DateTime(2026, 10, 5, 14),
    );

    expect(result, CalendarSyncResult.needCalendar);
  });

  test('changing the target calendar re-homes the event', () async {
    await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: DateTime(2026, 10, 5, 14),
    );
    calendars = [
      ...calendars,
      {
        'id': '3',
        'name': 'Work',
        'accountName': 'me@work.com',
        'isReadOnly': false,
      },
    ];
    await service.setTargetCalendar(
      const DeviceCalendar(id: '3', name: 'Work'),
    );

    await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: DateTime(2026, 10, 5, 14),
    );

    // Old event removed, fresh one created in the new calendar.
    expect(calls.where((c) => c.method == 'deleteEvent'), isNotEmpty);
    final upsert = calls.lastWhere((c) => c.method == 'createOrUpdateEvent');
    final args = Map<String, Object?>.from(upsert.arguments as Map);
    expect(args['calendarId'], '3');
    expect(args['eventId'], isNull);
    expect(service.linkFor('atom-1')?.calendarId, '3');
  });

  test('links survive a new service instance (persisted)', () async {
    await service.syncMeeting(
      atomId: 'atom-1',
      title: 'Standup',
      start: DateTime(2026, 10, 5, 14),
    );

    final revived = DeviceCalendarService();
    revived.debugSupportedOverride = true;
    revived.onInit();

    expect(revived.linkFor('atom-1')?.eventId, 'evt-100');
    expect(revived.linkFor('atom-1')?.date, DateTime(2026, 10, 5, 14));
  });
}
