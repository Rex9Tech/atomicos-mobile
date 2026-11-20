// test/services/google_calendar_service_test.dart
//
// The Google Calendar connect workflow: presence check → store hand-off when
// the app is missing (Play Store / App Store), or calendar access + meeting
// fetch when it is installed.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/services/device_calendar.service.dart';
import 'package:rexone_mobile/services/google_calendar.service.dart';
import 'package:rexone_mobile/services/meeting_reminder.service.dart';
import 'package:rexone_mobile/services/push_notification.service.dart';
import 'package:rexone_mobile/services/storage.service.dart';

import '../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorageService storage;
  late GoogleCalendarService service;
  final launched = <Uri>[];

  void mockCalendarBridge({required bool granted}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceCalendarChannel, (call) async {
      switch (call.method) {
        case 'hasPermissions':
        case 'requestPermissions':
          return granted;
        default:
          return null;
      }
    });
  }

  setUp(() {
    Get.testMode = true;
    storage = FakeStorageService();
    Get.put<StorageService>(storage);

    final device = DeviceCalendarService();
    device.debugSupportedOverride = true;
    Get.put<DeviceCalendarService>(device);

    Get.put<PushNotificationService>(FakePushNotificationService());
    Get.put<MeetingReminderService>(MeetingReminderService());

    service = GoogleCalendarService();
    service.debugSupportedOverride = true;
    service.debugPlatformOverride = 'android';
    service.debugLaunchUrl = (uri) async {
      launched.add(uri);
      return true;
    };
    service.debugCanLaunchUrl = (uri) async {
      launched.add(uri);
      return true;
    };
    Get.put<GoogleCalendarService>(service);
    launched.clear();

    mockCalendarBridge(granted: true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceCalendarChannel, null);
    Get.reset();
  });

  test('not installed → routes to the Play Store', () async {
    service.debugAndroidCanResolve = (_) async => false;

    final result = await service.connect();

    expect(result, GoogleCalendarConnectResult.storeOpened);
    expect(launched.single.toString(), googleCalendarPlayStoreUrl);
    expect(storage.getGoogleCalendarConnected(), false);
  });

  test('installed → requests access and connects', () async {
    service.debugAndroidCanResolve = (_) async => true;

    final result = await service.connect();

    expect(result, GoogleCalendarConnectResult.connected);
    expect(storage.getGoogleCalendarConnected(), true);
    expect(
      service.connected.value,
      true,
      reason: 'the settings status UI observes this flag',
    );
  });

  test('iOS store fallback uses the App Store URL', () async {
    service.debugPlatformOverride = 'ios';
    service.debugCanLaunchUrl = (uri) async {
      launched.add(uri);
      return false; // Google Calendar app not installed
    };

    final result = await service.connect();

    expect(result, GoogleCalendarConnectResult.storeOpened);
    expect(launched.last.toString(), googleCalendarAppStoreUrl);
  });

  test('unsupported platform reports unsupported', () async {
    service.debugSupportedOverride = false;

    final result = await service.connect();

    expect(result, GoogleCalendarConnectResult.unsupported);
  });

  test('permission denied stops before connecting', () async {
    service.debugAndroidCanResolve = (_) async => true;
    mockCalendarBridge(granted: false);

    final result = await service.connect();

    expect(result, GoogleCalendarConnectResult.permissionDenied);
    expect(storage.getGoogleCalendarConnected(), false);
  });

  test('upcomingEvents parses the native bridge payload', () async {
    final start = DateTime.now().add(const Duration(hours: 3));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceCalendarChannel, (call) async {
      if (call.method == 'listUpcomingEvents') {
        return [
          {
            'eventId': 'e1',
            'calendarId': '1',
            'title': 'Standup',
            'startMillis': start.millisecondsSinceEpoch,
            'endMillis': start
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch,
            'allDay': false,
          },
        ];
      }
      return null;
    });

    final meetings = await Get.find<DeviceCalendarService>().upcomingEvents();

    expect(meetings, hasLength(1));
    expect(meetings.single.title, 'Standup');
    expect(meetings.single.isTimed, true);
    expect(
      meetings.single.start.millisecondsSinceEpoch,
      start.millisecondsSinceEpoch,
    );
  });

  test('disconnect clears the flag and the reactive status', () async {
    service.debugAndroidCanResolve = (_) async => true;
    await service.connect();
    expect(service.connected.value, true);

    await service.disconnect();

    expect(storage.getGoogleCalendarConnected(), false);
    expect(service.connected.value, false);
  });

  test('a fresh service re-reads the persisted flag', () {
    storage.setGoogleCalendarConnected(true);
    // GetxService instances need force — plain delete refuses them.
    Get.delete<GoogleCalendarService>(force: true);

    final fresh = GoogleCalendarService();
    fresh.debugSupportedOverride = true;
    Get.put<GoogleCalendarService>(fresh);

    expect(fresh.connected.value, true);
  });
}
