// lib/services/google_calendar.service.dart
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'device_calendar.service.dart';
import 'meeting_reminder.service.dart';
import 'storage.service.dart';

/// The Google Calendar app on Android (Play Store listing id).
const String googleCalendarAndroidPackage = 'com.google.android.calendar';

/// The URL scheme the Google Calendar iOS app registers.
const String googleCalendarIosUrlScheme = 'googlecalendar://';

const String googleCalendarPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.google.android.calendar';

const String googleCalendarAppStoreUrl =
    'https://apps.apple.com/app/id909319292';

/// Outcome of the “Connect Google Calendar” action.
enum GoogleCalendarConnectResult {
  /// The app is present, calendar access granted, meetings fetched.
  connected,

  /// The app is not installed — the visitor was sent to the store.
  storeOpened,

  /// Calendar access was refused.
  permissionDenied,

  /// Not running on a supported platform.
  unsupported,

  /// Something failed along the way.
  failed,
}

typedef GoogleCalendarUrlCheck = Future<bool> Function(Uri uri);
typedef GoogleCalendarUrlLaunch = Future<bool> Function(Uri uri);
typedef GoogleCalendarPackageCheck = Future<bool> Function(String package);
typedef GoogleCalendarPackageLaunch = Future<bool> Function(String package);

/// Bridges AtomicOS to the Google Calendar app: presence checks, the store
/// hand-off when it is missing, and the connect flow that unlocks meeting
/// fetch + upcoming-meeting reminders.
///
/// TODO(business-workflow): the connected branch grows with the real workflow
/// (server sync, event creation, etc.) once it is specified.
class GoogleCalendarService extends GetxService {
  late final StorageService _storage;
  late final DeviceCalendarService _deviceCalendar;
  late final MeetingReminderService _reminders;

  /// Platform gate — tests flip this on.
  @visibleForTesting
  bool debugSupportedOverride = false;

  /// Platform override for tests: 'android' or 'ios'.
  @visibleForTesting
  String? debugPlatformOverride;

  @visibleForTesting
  GoogleCalendarUrlCheck? debugCanLaunchUrl;

  @visibleForTesting
  GoogleCalendarUrlLaunch? debugLaunchUrl;

  @visibleForTesting
  GoogleCalendarPackageCheck? debugAndroidCanResolve;

  @visibleForTesting
  GoogleCalendarPackageLaunch? debugAndroidLaunch;

  bool get _isAndroid => debugPlatformOverride != null
      ? debugPlatformOverride == 'android'
      : Platform.isAndroid;

  bool get _isIOS =>
      debugPlatformOverride != null ? debugPlatformOverride == 'ios' : Platform.isIOS;

  bool get _supported =>
      debugSupportedOverride || Platform.isAndroid || Platform.isIOS;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _deviceCalendar = Get.find<DeviceCalendarService>();
    _reminders = Get.find<MeetingReminderService>();
  }

  /// Whether the user connected Google Calendar (persisted flag).
  bool get isConnected => _storage.getGoogleCalendarConnected();

  /// Is the Google Calendar app installed on this device?
  Future<bool> isInstalled() async {
    if (!_supported) return false;
    if (_isAndroid) return _androidCanResolve(googleCalendarAndroidPackage);
    return _canLaunchUrl(Uri.parse(googleCalendarIosUrlScheme));
  }

  /// Opens the Google Calendar app (no-op when it is not installed).
  Future<bool> openApp() async {
    if (!_supported) return false;
    if (_isAndroid) return _androidLaunch(googleCalendarAndroidPackage);
    return _launchUrl(Uri.parse(googleCalendarIosUrlScheme));
  }

  /// The store page for this platform (null off-platform).
  Uri? storeUrl() {
    if (_isAndroid) return Uri.parse(googleCalendarPlayStoreUrl);
    if (_isIOS) return Uri.parse(googleCalendarAppStoreUrl);
    return null;
  }

  /// Opens this platform's store page for Google Calendar.
  Future<bool> openStore() async {
    final url = storeUrl();
    if (!_supported || url == null) return false;
    return _launchUrl(url);
  }

  /// The popup's “Connect” action:
  /// - no Google Calendar app → route to the store;
  /// - app present → request calendar access, fetch the upcoming meetings and
  ///   arm the meeting reminders.
  Future<GoogleCalendarConnectResult> connect() async {
    if (!_supported) return GoogleCalendarConnectResult.unsupported;

    if (!await isInstalled()) {
      return await openStore()
          ? GoogleCalendarConnectResult.storeOpened
          : GoogleCalendarConnectResult.failed;
    }

    // Native read bridges exist on Android (CalendarContract) and iOS
    // (EventKit) — on other platforms the connection is recorded and the
    // reminder pass is a no-op.
    if (_deviceCalendar.isSupported &&
        !await _deviceCalendar.ensurePermissions()) {
      return GoogleCalendarConnectResult.permissionDenied;
    }

    _storage.setGoogleCalendarConnected(true);
    await _reminders.refresh();
    await _reminders.ensureLiveSync();
    return GoogleCalendarConnectResult.connected;
  }

  /// Forgets the connection and cancels every armed reminder.
  Future<void> disconnect() async {
    _storage.setGoogleCalendarConnected(false);
    await _reminders.cancelAll();
  }

  // ===== platform hooks (overridden in tests) =====

  Future<bool> _canLaunchUrl(Uri uri) =>
      debugCanLaunchUrl?.call(uri) ?? canLaunchUrl(uri);

  Future<bool> _launchUrl(Uri uri) =>
      debugLaunchUrl?.call(uri) ??
      launchUrl(uri, mode: LaunchMode.externalApplication);

  Future<bool> _androidCanResolve(String package) async {
    final override = debugAndroidCanResolve;
    if (override != null) return override(package);
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: package,
      );
      return (await intent.canResolveActivity()) ?? false;
    } catch (error) {
      debugPrint('🗓️ [GoogleCalendar] resolve failed: $error');
      return false;
    }
  }

  Future<bool> _androidLaunch(String package) async {
    final override = debugAndroidLaunch;
    if (override != null) return override(package);
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: package,
      );
      await intent.launch();
      return true;
    } catch (error) {
      debugPrint('🗓️ [GoogleCalendar] launch failed: $error');
      return false;
    }
  }
}
