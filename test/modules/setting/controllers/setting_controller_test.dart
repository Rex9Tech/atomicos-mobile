// test/modules/setting/controllers/setting_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/modules/setting/controllers/setting.controller.dart';
import 'package:rexone_mobile/services/meeting_reminder.service.dart';
import 'package:rexone_mobile/services/storage.service.dart';
import '../../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorageService fakeStorage;
  late FakeMeetingReminderService fakeReminders;
  late SettingController controller;

  setUp(() {
    Get.testMode = true;
    fakeStorage = FakeStorageService();
    Get.put<StorageService>(fakeStorage);
    fakeReminders = FakeMeetingReminderService();
    Get.put<MeetingReminderService>(fakeReminders);
    controller = Get.put(SettingController());
  });

  tearDown(() {
    Get.reset();
  });

  group('SettingController - Theme Operations', () {
    test('initializes with default light mode when no storage setting exists', () {
      expect(controller.isDarkMode.value, isFalse);
      expect(controller.themeMode, equals(ThemeMode.light));
      expect(controller.themeLabel, equals('Light'));
    });

    test('toggleTheme switches dark mode and persists to storage', () {
      expect(controller.isDarkMode.value, isFalse);

      controller.toggleTheme();

      expect(controller.isDarkMode.value, isTrue);
      expect(controller.themeMode, equals(ThemeMode.dark));
      expect(controller.themeLabel, equals('Dark'));
      expect(fakeStorage.getThemeName(), equals(EThemePreference.dark.name));

      controller.toggleTheme();

      expect(controller.isDarkMode.value, isFalse);
      expect(controller.themeMode, equals(ThemeMode.light));
      expect(fakeStorage.getThemeName(), equals(EThemePreference.light.name));
    });

    test('setDarkMode sets explicit mode and persists', () {
      controller.setDarkMode(true);
      expect(controller.isDarkMode.value, isTrue);
      expect(fakeStorage.getThemeName(), equals(EThemePreference.dark.name));

      controller.setDarkMode(false);
      expect(controller.isDarkMode.value, isFalse);
      expect(fakeStorage.getThemeName(), equals(EThemePreference.light.name));
    });
  });

  group('SettingController - Locale Operations', () {
    test('initializes with en_US by default', () {
      expect(controller.localeCode.value, equals('en_US'));
      expect(controller.locale.languageCode, equals('en'));
      expect(controller.locale.countryCode, equals('US'));
    });

    testWidgets('setLocale updates locale and persists to storage', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
      controller.setLocale('my_MM');
      await tester.pumpAndSettle();

      expect(controller.localeCode.value, equals('my_MM'));
      expect(controller.locale.languageCode, equals('my'));
      expect(controller.locale.countryCode, equals('MM'));
      expect(fakeStorage.getLocaleCode(), equals('my_MM'));
      expect(controller.isLocale('my_MM'), isTrue);
    });

    testWidgets('cycleLocale rotates through supported locales', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
      controller.setLocale('en_US');
      await tester.pumpAndSettle();
      controller.cycleLocale();
      await tester.pumpAndSettle();

      expect(controller.localeCode.value, isNot(equals('en_US')));
    });

    testWidgets('resetToDefaults resets theme and restores en_US locale', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
      controller.setDarkMode(true);
      controller.setLocale('my_MM');
      await tester.pumpAndSettle();

      controller.resetToDefaults();
      await tester.pumpAndSettle();

      expect(controller.localeCode.value, equals('en_US'));
      expect(fakeStorage.getLocaleCode(), equals('en_US'));
    });
  });

  group('SettingController - Meeting alerts', () {
    test('defaults to alerts on with a 10-minute lead', () {
      expect(controller.meetingAlertsEnabled.value, isTrue);
      expect(controller.meetingAlertLeadMinutes.value, equals(10));
    });

    test('toggling alerts persists and re-arms the reminders', () {
      controller.setMeetingAlertsEnabled(false);

      expect(controller.meetingAlertsEnabled.value, isFalse);
      expect(fakeStorage.getMeetingAlertsEnabled(), isFalse);
      expect(fakeReminders.refreshCalls, greaterThan(0));
    });

    test('changing the lead time persists and re-arms the reminders', () {
      final before = fakeReminders.refreshCalls;

      controller.setMeetingAlertLeadMinutes(30);

      expect(controller.meetingAlertLeadMinutes.value, equals(30));
      expect(fakeStorage.getMeetingAlertLeadMinutes(), equals(30));
      expect(fakeReminders.refreshCalls, greaterThan(before));
    });
  });
}
