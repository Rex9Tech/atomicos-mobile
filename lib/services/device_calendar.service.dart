import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Thin wrapper around the DEVICE's built-in calendar.
///
/// The app no longer ships its own calendar screen: calendar actions hand the
/// job to the phone's calendar app (Google Calendar & friends) through
/// intents. No calendar permissions are required — the user reviews and
/// saves the event inside their own calendar.
class DeviceCalendarService extends GetxService {
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
}
