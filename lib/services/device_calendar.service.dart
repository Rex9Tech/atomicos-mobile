// lib/services/device_calendar.service.dart
import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'storage.service.dart';

/// Native bridge to the DEVICE calendar provider (Android CalendarContract).
/// Public + const so tests can mock the channel by name.
const MethodChannel deviceCalendarChannel = MethodChannel('atomicos/calendar');

/// A calendar available on the device.
class DeviceCalendar {
  const DeviceCalendar({
    required this.id,
    required this.name,
    this.accountName = '',
    this.isReadOnly = false,
  });

  final String id;
  final String name;
  final String accountName;
  final bool isReadOnly;

  factory DeviceCalendar.fromMap(Map<dynamic, dynamic> map) => DeviceCalendar(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    accountName: map['accountName']?.toString() ?? '',
    isReadOnly: map['isReadOnly'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'account_name': accountName,
    'is_read_only': isReadOnly,
  };

  static DeviceCalendar? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return DeviceCalendar(
      id: id,
      name: json['name']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      isReadOnly: json['is_read_only'] == true,
    );
  }
}

/// An upcoming meeting read from the device calendar (the user's Google
/// account events included).
class CalendarMeeting {
  const CalendarMeeting({
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
  });

  final String eventId;
  final String calendarId;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  /// A timed meeting with a name — the kind worth reminding about.
  bool get isTimed => !allDay && title.trim().isNotEmpty;

  factory CalendarMeeting.fromMap(Map<dynamic, dynamic> map) => CalendarMeeting(
    eventId: map['eventId']?.toString() ?? '',
    calendarId: map['calendarId']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    start: DateTime.fromMillisecondsSinceEpoch(
      (map['startMillis'] as num?)?.toInt() ?? 0,
    ),
    end: DateTime.fromMillisecondsSinceEpoch(
      (map['endMillis'] as num?)?.toInt() ?? 0,
    ),
    allDay: map['allDay'] == true,
  );
}

/// Result of trying to write a meeting into the device calendar.
enum CalendarSyncResult {
  /// Created or updated — the meeting is now in the device calendar.
  synced,

  /// The user refused calendar access.
  permissionDenied,

  /// No writable calendar exists (or could be resolved) on this device.
  needCalendar,

  /// The write itself failed.
  failed,

  /// Not running on a supported platform.
  unsupported,
}

/// A persisted link between an atom and its event in the device calendar.
class CalendarEventLink {
  const CalendarEventLink({
    required this.atomId,
    required this.calendarId,
    required this.eventId,
    required this.date,
  });

  final String atomId;
  final String calendarId;
  final String eventId;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'atom_id': atomId,
    'calendar_id': calendarId,
    'event_id': eventId,
    'date': date.toIso8601String(),
  };

  static CalendarEventLink? fromJson(Map<String, dynamic> json) {
    final atomId = json['atom_id']?.toString() ?? '';
    final calendarId = json['calendar_id']?.toString() ?? '';
    final eventId = json['event_id']?.toString() ?? '';
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    if (atomId.isEmpty || calendarId.isEmpty || eventId.isEmpty || date == null) {
      return null;
    }
    return CalendarEventLink(
      atomId: atomId,
      calendarId: calendarId,
      eventId: eventId,
      date: date,
    );
  }
}

/// The device calendar owns meeting events: this service writes them through
/// the native CalendarContract bridge (so they appear in the built-in calendar
/// app automatically), remembers the atom→event links locally, and falls back
/// to a calendar-app hand-off when access was refused.
class DeviceCalendarService extends GetxService {
  late final StorageService _storage;

  /// The native bridges exist on Android (CalendarContract) and iOS
  /// (EventKit); tests flip this on.
  @visibleForTesting
  bool debugSupportedOverride = false;

  bool get _supported =>
      debugSupportedOverride || Platform.isAndroid || Platform.isIOS;

  /// Whether the native calendar bridge exists on this platform.
  bool get isSupported => _supported;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
  }

  // ============================================================
  // HAND-OFF FALLBACKS (open the calendar app / prefilled insert)
  // ============================================================

  /// Opens the user's default calendar app (MAIN + APP_CALENDAR intent).
  Future<bool> openCalendarApp() async {
    if (!Platform.isAndroid) return false;
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.APP_CALENDAR',
      );
      await intent.launch();
      return true;
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] openCalendarApp failed: $error');
      return false;
    }
  }

  /// Opens the calendar's "new event" screen prefilled with this meeting.
  /// Used only when calendar access was refused.
  Future<bool> addEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final event = Event(
        title: title,
        description: description,
        location: location,
        startDate: start,
        endDate: end,
      );
      return await Add2Calendar.addEvent2Cal(event);
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] addEvent failed: $error');
      return false;
    }
  }

  // ============================================================
  // NATIVE CALENDAR PROVIDER (silent, automatic)
  // ============================================================

  Future<bool> hasPermissions() async {
    if (!_supported) return false;
    try {
      final granted =
          await deviceCalendarChannel.invokeMethod<bool>('hasPermissions');
      return granted == true;
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] hasPermissions failed: $error');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (!_supported) return false;
    try {
      final granted =
          await deviceCalendarChannel.invokeMethod<bool>('requestPermissions');
      return granted == true;
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] requestPermissions failed: $error');
      return false;
    }
  }

  Future<bool> ensurePermissions() async =>
      (await hasPermissions()) || (await requestPermissions());

  // ============================================================
  // LIVE SYNC (calendar-change observer + background re-arm)
  // ============================================================

  /// Starts the native calendar-change observer: while the app process is
  /// alive, calendar edits trigger an instant reminder refresh.
  Future<void> startWatching() async {
    if (!_supported) return;
    try {
      await deviceCalendarChannel.invokeMethod<bool>('startWatching');
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] startWatching failed: $error');
    }
  }

  /// Stops the native calendar-change observer.
  Future<void> stopWatching() async {
    if (!_supported) return;
    try {
      await deviceCalendarChannel.invokeMethod<bool>('stopWatching');
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] stopWatching failed: $error');
    }
  }

  /// Schedules the periodic (~15 min) background reminder refresh so sync
  /// keeps working when the app process is dead.
  Future<void> scheduleBackgroundSync() async {
    if (!_supported) return;
    try {
      await deviceCalendarChannel.invokeMethod<bool>('scheduleBackgroundSync');
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] scheduleBackgroundSync failed: $error');
    }
  }

  /// Cancels the periodic background refresh (disconnect / logout).
  Future<void> cancelBackgroundSync() async {
    if (!_supported) return;
    try {
      await deviceCalendarChannel.invokeMethod<bool>('cancelBackgroundSync');
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] cancelBackgroundSync failed: $error');
    }
  }

  /// Writable calendars on the device (for the picker + target resolution).
  Future<List<DeviceCalendar>> availableCalendars() async {
    if (!_supported) return const [];
    try {
      final raw = await deviceCalendarChannel
              .invokeMethod<List<dynamic>>('listCalendars') ??
          const [];
      return raw
          .whereType<Map>()
          .map(DeviceCalendar.fromMap)
          .where((calendar) => calendar.id.isNotEmpty && !calendar.isReadOnly)
          .toList();
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] availableCalendars failed: $error');
      return const [];
    }
  }

  /// Upcoming meetings from the device calendar (the user's Google account
  /// events included), between now and [horizon].
  Future<List<CalendarMeeting>> upcomingEvents({
    Duration horizon = const Duration(hours: 48),
  }) async {
    if (!_supported) return const [];
    try {
      final now = DateTime.now();
      final raw = await deviceCalendarChannel
              .invokeMethod<List<dynamic>>('listUpcomingEvents', {
        'startMillis': now.millisecondsSinceEpoch,
        'endMillis': now.add(horizon).millisecondsSinceEpoch,
      }) ??
          const [];
      return raw
          .whereType<Map>()
          .map(CalendarMeeting.fromMap)
          .where((meeting) => meeting.eventId.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] upcomingEvents failed: $error');
      return const [];
    }
  }

  DeviceCalendar? get targetCalendar {
    final raw = _storage.getCalendarTarget();
    if (raw == null) return null;
    return DeviceCalendar.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> setTargetCalendar(DeviceCalendar calendar) async =>
      _storage.setCalendarTarget(calendar.toJson());

  /// Resolves where events go: the saved pick when still present, otherwise
  /// the first writable calendar (remembered so we never ask twice).
  Future<DeviceCalendar?> _resolveTarget() async {
    final calendars = await availableCalendars();
    if (calendars.isEmpty) return null;
    final saved = targetCalendar;
    if (saved != null) {
      for (final calendar in calendars) {
        if (calendar.id == saved.id) return calendar;
      }
    }
    final chosen = calendars.first;
    await setTargetCalendar(chosen);
    return chosen;
  }

  // ============================================================
  // ATOM ↔ EVENT LINKS (persisted)
  // ============================================================

  CalendarEventLink? linkFor(String atomId) {
    final raw = _storage.getCalendarEventLinks()[atomId];
    if (raw is! Map) return null;
    return CalendarEventLink.fromJson(Map<String, dynamic>.from(raw));
  }

  void _saveLink(CalendarEventLink link) {
    final links = _storage.getCalendarEventLinks();
    links[link.atomId] = link.toJson();
    _storage.setCalendarEventLinks(links);
  }

  void _clearLink(String atomId) {
    final links = _storage.getCalendarEventLinks();
    if (links.remove(atomId) != null) {
      _storage.setCalendarEventLinks(links);
    }
  }

  // ============================================================
  // SYNC
  // ============================================================

  /// Creates (or updates) this atom's event in the device calendar — silently,
  /// keeping exactly ONE event per atom, updated on every later edit.
  Future<CalendarSyncResult> syncMeeting({
    required String atomId,
    required String title,
    required DateTime start,
    Duration duration = const Duration(hours: 1),
    String? description,
  }) async {
    if (!_supported) return CalendarSyncResult.unsupported;
    if (!await ensurePermissions()) return CalendarSyncResult.permissionDenied;

    final calendar = await _resolveTarget();
    if (calendar == null) return CalendarSyncResult.needCalendar;

    // An event that lives in a different calendar is re-homed into the new one.
    var existing = linkFor(atomId);
    if (existing != null && existing.calendarId != calendar.id) {
      await removeMeeting(atomId);
      existing = null;
    }

    try {
      final eventId = await deviceCalendarChannel
          .invokeMethod<String>('createOrUpdateEvent', {
            'calendarId': calendar.id,
            'eventId': existing?.eventId,
            'title': title,
            'description': description,
            'startMillis': start.millisecondsSinceEpoch,
            'endMillis': start.add(duration).millisecondsSinceEpoch,
            'reminderMinutes': 10,
          });
      if (eventId == null || eventId.isEmpty) {
        return CalendarSyncResult.failed;
      }
      _saveLink(
        CalendarEventLink(
          atomId: atomId,
          calendarId: calendar.id,
          eventId: eventId,
          date: start,
        ),
      );
      return CalendarSyncResult.synced;
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] syncMeeting failed: $error');
      return CalendarSyncResult.failed;
    }
  }

  /// Removes this atom's event from the device calendar (if it has one).
  Future<bool> removeMeeting(String atomId) async {
    final link = linkFor(atomId);
    if (link == null) return true;
    if (!_supported) return false;
    try {
      await deviceCalendarChannel.invokeMethod<bool>('deleteEvent', {
        'calendarId': link.calendarId,
        'eventId': link.eventId,
      });
      // Deleted — or already gone from the calendar — either way we stop
      // tracking it.
      _clearLink(atomId);
      return true;
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] removeMeeting failed: $error');
      return false;
    }
  }

  /// Creates (or updates) the atom's NEXT-MEETING event — the date mentioned
  /// in the AI summary — kept separate from the atom's own meeting-date event.
  Future<CalendarSyncResult> syncNextMeeting({
    required String atomId,
    required String title,
    required DateTime start,
    Duration duration = const Duration(hours: 1),
    String? description,
  }) async {
    if (!_supported) return CalendarSyncResult.unsupported;
    if (!await ensurePermissions()) return CalendarSyncResult.permissionDenied;

    final calendar = await _resolveTarget();
    if (calendar == null) return CalendarSyncResult.needCalendar;

    final linkKey = nextMeetingKey(atomId);
    var existing = linkFor(linkKey);
    if (existing != null && existing.calendarId != calendar.id) {
      await _deleteLinkedEvent(linkKey);
      existing = null;
    }

    try {
      final eventId = await deviceCalendarChannel
          .invokeMethod<String>('createOrUpdateEvent', {
            'calendarId': calendar.id,
            'eventId': existing?.eventId,
            'title': title,
            'description': description,
            'startMillis': start.millisecondsSinceEpoch,
            'endMillis': start.add(duration).millisecondsSinceEpoch,
            'reminderMinutes': 10,
          });
      if (eventId == null || eventId.isEmpty) {
        return CalendarSyncResult.failed;
      }
      _saveLink(
        CalendarEventLink(
          atomId: linkKey,
          calendarId: calendar.id,
          eventId: eventId,
          date: start,
        ),
      );
      return CalendarSyncResult.synced;
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] syncNextMeeting failed: $error');
      return CalendarSyncResult.failed;
    }
  }

  /// The persisted next-meeting link for an atom (null until created).
  CalendarEventLink? nextMeetingLinkFor(String atomId) =>
      linkFor(nextMeetingKey(atomId));

  /// The storage key for an atom's next-meeting event link.
  static String nextMeetingKey(String atomId) => 'next_meeting:$atomId';

  Future<void> _deleteLinkedEvent(String linkKey) async {
    final link = linkFor(linkKey);
    if (link == null) return;
    try {
      await deviceCalendarChannel.invokeMethod<bool>('deleteEvent', {
        'calendarId': link.calendarId,
        'eventId': link.eventId,
      });
    } catch (error) {
      debugPrint('🗓️ [DeviceCalendar] deleteLinkedEvent failed: $error');
    }
    _clearLink(linkKey);
  }
}
