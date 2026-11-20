// test/services/meeting_reminder_service_test.dart
//
// Meeting alerts are configurable in Settings: on/off + how early the
// reminder fires. The arming pass honours both — this covers the default
// lead, a lead change (re-arm) and switching alerts off (drop).
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/services/device_calendar.service.dart';
import 'package:rexone_mobile/services/meeting_reminder.service.dart';
import 'package:rexone_mobile/services/push_notification.service.dart';
import 'package:rexone_mobile/services/storage.service.dart';

import '../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorageService storage;
  late FakePushNotificationService push;
  late MeetingReminderService service;
  late DateTime meetingStart;

  void mockCalendar({required List<Map<String, Object?>> events}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceCalendarChannel, (call) async {
      switch (call.method) {
        case 'hasPermissions':
        case 'requestPermissions':
          return true;
        case 'listUpcomingEvents':
          return events;
        default:
          return null;
      }
    });
  }

  setUp(() {
    Get.testMode = true;
    storage = FakeStorageService();
    Get.put<StorageService>(storage);
    storage.setGoogleCalendarConnected(true);

    final device = DeviceCalendarService();
    device.debugSupportedOverride = true;
    Get.put<DeviceCalendarService>(device);

    push = FakePushNotificationService();
    Get.put<PushNotificationService>(push);

    service = MeetingReminderService();
    Get.put<MeetingReminderService>(service);

    meetingStart = DateTime.now().add(const Duration(hours: 3));
    mockCalendar(
      events: [
        {
          'eventId': 'meet-1',
          'calendarId': '1',
          'title': 'Design review',
          'startMillis': meetingStart.millisecondsSinceEpoch,
          'endMillis': meetingStart
              .add(const Duration(minutes: 30))
              .millisecondsSinceEpoch,
          'allDay': false,
        },
      ],
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceCalendarChannel, null);
    Get.reset();
  });

  test('arms a default 10-minute alert for an upcoming meeting', () async {
    await service.refresh();

    expect(push.scheduledLocalNotifications, hasLength(1));
    final when = push.scheduledLocalNotifications.single['when'] as DateTime;
    expect(
      when.difference(meetingStart).inMinutes,
      -10,
      reason: 'default lead time is 10 minutes before the start',
    );
    expect(storage.getMeetingReminders().keys, contains('meet-1'));
  });

  test('changing the lead time re-arms the reminder', () async {
    await service.refresh();
    final firstId = push.scheduledLocalNotifications.single['id'] as int;

    storage.setMeetingAlertLeadMinutes(30);
    await service.refresh();

    expect(
      push.cancelledLocalNotificationIds,
      contains(firstId),
      reason: 'the 10-minute alert is dropped when the lead changes',
    );
    expect(push.scheduledLocalNotifications, hasLength(2));
    final when = push.scheduledLocalNotifications.last['when'] as DateTime;
    expect(when.difference(meetingStart).inMinutes, -30);
    final saved = storage.getMeetingReminders()['meet-1'] as Map;
    expect(saved['lead'], 30);
  });

  test('switching alerts off drops the armed reminder', () async {
    await service.refresh();
    expect(push.scheduledLocalNotifications, hasLength(1));

    storage.setMeetingAlertsEnabled(false);
    await service.refresh();

    expect(push.cancelledLocalNotificationIds, hasLength(1));
    expect(storage.getMeetingReminders(), isEmpty);
    expect(
      push.scheduledLocalNotifications,
      hasLength(1),
      reason: 'nothing new is armed while alerts are off',
    );
  });
}
