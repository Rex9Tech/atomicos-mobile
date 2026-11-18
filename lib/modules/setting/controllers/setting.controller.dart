import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import '../../../services/google_calendar.service.dart';
import '../../../services/meeting_reminder.service.dart';
import '../../../services/storage.service.dart';
import '../../../locales/app_translations.dart';
import 'package:rexone_mobile/constants/constants.dart';

/// Theme + locale settings, persisted with GetStorage.
class SettingController extends GetxController {
  final StorageService _storage = Get.find();

  // ===== OBSERVABLES =====
  var isDarkMode = false.obs; // true = dark, false = light
  var localeCode = 'en_US'.obs; // e.g. 'en_US', 'es_ES', 'my_MM'
  var appVersion = ''.obs; // e.g. '1.0.0'

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
  /// Shows the “Connect Google Calendar” popup and runs the connect flow:
  /// routes to the store when the Google Calendar app is missing, otherwise
  /// unlocks the meeting fetch + upcoming-meeting reminders.
  Future<void> connectGoogleCalendar(BuildContext context) async {
    Get.addTranslations(AppTranslations().keys);
    final shouldConnect = await AppDialog.confirm(
      context: context,
      title: AppLocales.calendar.connectTitle.tr,
      message: AppLocales.calendar.connectMessage.tr,
      confirmLabel: AppLocales.calendar.connectAction.tr,
      cancelLabel: AppLocales.calendar.notNow.tr,
    );
    if (!shouldConnect) return;

    final result = await Get.find<GoogleCalendarService>().connect();
    switch (result) {
      case GoogleCalendarConnectResult.connected:
        AppSnackbar.success(
          AppLocales.calendar.connectDone.trParams({
            'count': '${Get.find<MeetingReminderService>().armedCount}',
          }),
        );
      case GoogleCalendarConnectResult.storeOpened:
        AppSnackbar.info(AppLocales.calendar.storeOpened.tr);
      case GoogleCalendarConnectResult.permissionDenied:
        AppSnackbar.error(AppLocales.calendar.permissionDenied.tr);
      case GoogleCalendarConnectResult.unsupported:
      case GoogleCalendarConnectResult.failed:
        AppSnackbar.error(AppLocales.calendar.connectFailed.tr);
    }
  }
}
