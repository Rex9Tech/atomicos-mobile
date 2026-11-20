import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import '../../../services/storage.service.dart';
import '../../../services/google_calendar.service.dart';
import '../../../services/meeting_reminder.service.dart';
import '../../../locales/app_translations.dart';
import 'package:rexone_mobile/constants/constants.dart';
import '../helpers/google_calendar_connect.helper.dart';

/// Theme + locale settings, persisted with GetStorage.
class SettingController extends GetxController {
  final StorageService _storage = Get.find();
  final MeetingReminderService _reminders = Get.find();

  // ===== OBSERVABLES =====
  var isDarkMode = false.obs; // true = dark, false = light
  var localeCode = 'en_US'.obs; // e.g. 'en_US', 'es_ES', 'my_MM'
  var appVersion = ''.obs; // e.g. '1.0.0'
  var meetingAlertsEnabled = true.obs; // Meeting alerts on/off
  var meetingAlertLeadMinutes = 10.obs; // minutes before the meeting

  // ===== THEME MODE =====
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  IconData get themeIcon =>
      isDarkMode.value ? Design.icons.darkMode : Design.icons.lightMode;

  String get themeLabel => isDarkMode.value ? 'Dark' : 'Light';

  // ===== LOCALE =====
  Locale get locale {
    final parts = localeCode.value.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : '');
  }

  String get currentLanguageName =>
      AppTranslations.supportedLocales[localeCode.value] ?? 'English';

  List<MapEntry<String, String>> get supportedLocales =>
      AppTranslations.supportedLocales.entries.toList();

  // ===== INIT =====
  @override
  void onInit() {
    super.onInit();
    Get.addTranslations(AppTranslations().keys);
    final savedTheme = _storage.getThemeName();
    isDarkMode.value = savedTheme == EThemePreference.dark.name;
    localeCode.value = _storage.getLocaleCode() ?? 'en_US';
    meetingAlertsEnabled.value = _storage.getMeetingAlertsEnabled();
    meetingAlertLeadMinutes.value = _storage.getMeetingAlertLeadMinutes();
    _loadAppVersion();
  }

  // ===== APP VERSION =====
  void _loadAppVersion() {
    appVersion.value = AppInfo.version;
  }

  // ===== THEME METHODS =====
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _storage.setThemeName(
      isDarkMode.value
          ? EThemePreference.dark.name
          : EThemePreference.light.name,
    );
    Get.changeThemeMode(themeMode);
    update();
  }

  void setDarkMode(bool isDark) {
    isDarkMode.value = isDark;
    _storage.setThemeName(
      isDark ? EThemePreference.dark.name : EThemePreference.light.name,
    );
    Get.changeThemeMode(themeMode);
  }

  // ===== LOCALE METHODS =====
  void setLocale(String code) {
    localeCode.value = code;
    _storage.setLocaleCode(code);
    Get.updateLocale(locale);
    update();
  }

  void changeLocale(String code) => setLocale(code);

  void cycleLocale() {
    final keys = AppTranslations.supportedLocales.keys.toList();
    final currentIndex = keys.indexOf(localeCode.value);
    final nextIndex = (currentIndex + 1) % keys.length;
    setLocale(keys[nextIndex]);
  }

  // ===== CONVENIENCE =====
  bool isLocale(String code) => localeCode.value == code;

  // ===== RESET =====
  void resetToDefaults() {
    isDarkMode.value = Get.isDarkMode;
    _storage.setThemeName(
      isDarkMode.value
          ? EThemePreference.dark.name
          : EThemePreference.light.name,
    );
    Get.changeThemeMode(themeMode);
    setLocale('en_US');
  }

  // ===== GOOGLE CALENDAR =====
  /// Shows the connect popup, then routes to the store when the Google
  /// Calendar app is missing, otherwise unlocks the meeting fetch +
  /// upcoming-meeting reminders. (Flow lives in the shared helper — also used
  /// by the post-login prompt.)
  Future<void> connectGoogleCalendar(BuildContext context) =>
      promptGoogleCalendarConnect(context);

  /// Forgets the Google Calendar connection and cancels armed reminders.
  Future<void> disconnectGoogleCalendar() =>
      Get.find<GoogleCalendarService>().disconnect();

  // ===== MEETING ALERTS =====
  /// How early a meeting alert can fire, in minutes before the start.
  static const meetingAlertLeadOptions = <int>[5, 10, 15, 30, 60];

  /// Meeting alert on/off — persisted and applied immediately (arming is
  /// dropped when off; switching on re-arms the upcoming meetings).
  void setMeetingAlertsEnabled(bool enabled) {
    meetingAlertsEnabled.value = enabled;
    _storage.setMeetingAlertsEnabled(enabled);
    _reminders.refresh();
  }

  /// How early meeting alerts fire — persisted and re-armed immediately.
  void setMeetingAlertLeadMinutes(int minutes) {
    meetingAlertLeadMinutes.value = minutes;
    _storage.setMeetingAlertLeadMinutes(minutes);
    _reminders.refresh();
  }
}
