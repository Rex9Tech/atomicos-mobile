// lib/services/meeting_reminder.service.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'package:rexone_mobile/locales/app_locales.dart';
import 'package:rexone_mobile/locales/app_translations.dart';

import 'device_calendar.service.dart';
import 'push_notification.service.dart';
import 'storage.service.dart';

/// Arms LOCAL notifications for upcoming calendar meetings: fetches the next
/// [horizon] of events from the device calendar (which carries the user's
/// Google account) and schedules one reminder [leadTime] before each meeting.
///
/// Reminders are re-armed on app start, on resume and right after the
/// “Connect Google Calendar” flow completes.
class MeetingReminderService extends GetxService with WidgetsBindingObserver {
  late final StorageService _storage;
  late final DeviceCalendarService _deviceCalendar;
  late final PushNotificationService _push;

  /// How early a meeting reminder fires — configurable in Settings
  /// ("Meeting alerts", default 10 minutes).
  Duration get leadTime =>
      Duration(minutes: _storage.getMeetingAlertLeadMinutes());

  /// How far ahead meetings are fetched and armed.
  static const Duration horizon = Duration(hours: 48);

  /// Meeting reminder notification ids live in this band so they never clash
  /// with other local notifications (media downloads, etc.).
  static const int notificationIdBase = 72000;

  static const String _channelId = 'atomicos_meetings';

  /// Native calendar-change events (CalendarWatcher on Android) — live sync
  /// while the app process is alive.
  static const MethodChannel _eventsChannel = MethodChannel(
    'atomicos/calendar_events',
  );

  bool _refreshInFlight = false;
  DateTime? _lastNativeRefresh;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _deviceCalendar = Get.find<DeviceCalendarService>();
    _push = Get.find<PushNotificationService>();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid || Platform.isIOS) {
      _eventsChannel.setMethodCallHandler(_onNativeCalendarEvent);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  /// Fired by the native calendar observer (debounced ~1 s) whenever the
  /// device calendar changes — re-arm reminders right away.
  Future<dynamic> _onNativeCalendarEvent(MethodCall call) async {
    if (call.method != 'calendarChanged') return null;
    final now = DateTime.now();
    final last = _lastNativeRefresh;
    if (last != null && now.difference(last) < const Duration(seconds: 3)) {
      return null;
    }
    _lastNativeRefresh = now;
    await refresh();
    return null;
  }

  /// Whether the user connected Google Calendar.
  bool get isConnected => _storage.getGoogleCalendarConnected();

  /// Whether meeting alerts are switched on (Settings → Meeting alerts).
  bool get alertsEnabled => _storage.getMeetingAlertsEnabled();

  /// How many reminders are currently armed.
  int get armedCount => _storage.getMeetingReminders().length;

  /// Startup pass — silent: refreshes only when the user already connected
  /// and calendar access is in place. Never prompts for anything.
  Future<void> refreshFromStartup() async {
    if (!isConnected || !_deviceCalendar.isSupported) return;
    if (!await _deviceCalendar.hasPermissions()) return;
    await refresh();
    await ensureLiveSync();
  }

  /// Keeps the live-sync paths armed: the native calendar observer (instant
  /// updates while the app process is alive) and the periodic background
  /// sync (WorkManager, ~15 min, when the app is closed).
  Future<void> ensureLiveSync() async {
    if (!isConnected || !_deviceCalendar.isSupported) return;
    await _deviceCalendar.startWatching();
    await _deviceCalendar.scheduleBackgroundSync();
  }

  /// Fetches upcoming meetings and (re)arms their reminders. Safe to call
  /// often — it is idempotent and guards against overlapping runs.
  Future<void> refresh() async {
    if (!isConnected || _refreshInFlight) return;
    if (!_deviceCalendar.isSupported) return;
    _refreshInFlight = true;
    try {
      // Alerts switched off: drop anything armed and stay out of the way
      // (switching them back on re-arms through the same refresh pass).
      if (!alertsEnabled) {
        await _cancelArmed();
        return;
      }
      if (!await _deviceCalendar.hasPermissions()) return;
      if (!_push.isLocalNotificationsReady) return;

      Get.addTranslations(AppTranslations().keys);
      await _push.createAndroidChannel(
        AndroidNotificationChannel(
          _channelId,
          AppLocales.calendar.channelName.tr,
          description: AppLocales.calendar.channelDescription.tr,
          importance: Importance.high,
        ),
      );

      final meetings = await _deviceCalendar.upcomingEvents(horizon: horizon);
      final now = DateTime.now();

      // Events AtomicOS created itself (atom meeting dates, next meetings)
      // already carry a calendar reminder — skip them so the user never gets
      // two notifications for the same meeting.
      final managedEventIds = _storage
          .getCalendarEventLinks()
          .values
          .whereType<Map>()
          .map((link) => link['event_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Desired: timed meetings whose lead moment is still ahead.
      final desired = <String, CalendarMeeting>{};
      for (final meeting in meetings) {
        if (!meeting.isTimed || meeting.start.isBefore(now)) continue;
        if (managedEventIds.contains(meeting.eventId)) continue;
        if (!meeting.start.subtract(leadTime).isAfter(now)) continue;
        desired[meeting.eventId] = meeting;
      }

      final tracked = _storage.getMeetingReminders();
      final leadMinutes = _storage.getMeetingAlertLeadMinutes();

      // Drop reminders whose meeting vanished, moved, or whose lead time
      // changed in Settings (they get re-armed below with the new lead).
      for (final eventId in tracked.keys.toList()) {
        final saved = _savedEntry(tracked[eventId]);
        final meeting = desired[eventId];
        final savedLead = (saved['lead'] as num?)?.toInt();
        if (meeting == null ||
            meeting.start.toIso8601String() != saved['start']?.toString() ||
            savedLead != leadMinutes) {
          final id = (saved['notification_id'] as num?)?.toInt();
          if (id != null) await _push.cancelLocalNotification(id);
          tracked.remove(eventId);
        }
      }

      // Arm the missing ones.
      for (final meeting in desired.values) {
        if (tracked.containsKey(meeting.eventId)) continue;
        final notificationId = _notificationIdFor(meeting.eventId);
        await _push.scheduleLocalNotification(
          id: notificationId,
          when: meeting.start.subtract(leadTime),
          title: AppLocales.calendar.reminderTitle.tr,
          body: AppLocales.calendar.reminderBody.trParams({
            'title': meeting.title,
            'time': _formatTime(meeting.start),
          }),
          details: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              AppLocales.calendar.channelName.tr,
              channelDescription: AppLocales.calendar.channelDescription.tr,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: meeting.eventId,
        );
        tracked[meeting.eventId] = {
          'start': meeting.start.toIso8601String(),
          'notification_id': notificationId,
          'title': meeting.title,
          'lead': leadMinutes,
        };
      }

      _storage.setMeetingReminders(tracked);
    } catch (error) {
      debugPrint('🗓️ [MeetingReminder] refresh failed: $error');
    } finally {
      _refreshInFlight = false;
    }
  }

  /// Cancels every armed reminder (disconnect, logout, …).
  Future<void> cancelAll() async {
    await _cancelArmed();
    await _deviceCalendar.stopWatching();
    await _deviceCalendar.cancelBackgroundSync();
  }

  /// Cancels whatever is armed but leaves the connection + watchers alone
  /// (used when meeting alerts are switched off in Settings).
  Future<void> _cancelArmed() async {
    final tracked = _storage.getMeetingReminders();
    for (final entry in tracked.values) {
      final saved = _savedEntry(entry);
      final id = (saved['notification_id'] as num?)?.toInt();
      if (id != null) await _push.cancelLocalNotification(id);
    }
    _storage.setMeetingReminders(<String, dynamic>{});
  }

  static Map<String, dynamic> _savedEntry(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static int _notificationIdFor(String eventId) =>
      notificationIdBase + (eventId.hashCode.abs() % 20000);

  static String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
