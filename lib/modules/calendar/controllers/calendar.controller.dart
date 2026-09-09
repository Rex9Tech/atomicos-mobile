import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/calendar_event.model.dart';
import '../services/calendar.service.dart';

class CalendarController extends GetxController {
  final CalendarService _calendar = Get.find<CalendarService>();

  final RxString selectedRange = 'Week'.obs;
  final RxInt selectedDay = 7.obs;

  final RxList<CalendarEventModel> events = <CalendarEventModel>[].obs;
  final RxBool isLoadingEvents = false.obs;
  final RxBool hasEventsError = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  void selectRange(String value) {
    selectedRange.value = value;
  }

  void selectDay(int value) {
    selectedDay.value = value;
  }

  Future<void> loadEvents({bool upcoming = false}) async {
    isLoadingEvents.value = true;
    hasEventsError.value = false;
    try {
      final result = await _calendar.getEvents(upcoming: upcoming);
      if (result.success) {
        events.assignAll(result.records);
      } else {
        hasEventsError.value = true;
      }
    } catch (error) {
      debugPrint('📅 [CalendarController] Error loading events: $error');
      hasEventsError.value = true;
    } finally {
      isLoadingEvents.value = false;
    }
  }

  /// True when any event starts on [day] of the current month/year —
  /// drives the calendar-grid highlight dots.
  bool hasEventOnDay(int day) {
    final now = DateTime.now();
    return events.any((event) {
      final start = _parseDate(event.startAt);
      return start != null &&
          start.year == now.year &&
          start.month == now.month &&
          start.day == day;
    });
  }

  /// HH:mm for an event's start (local time), or null when unparsable.
  String? eventTime(CalendarEventModel event) => _formatTime(event.startAt);

  DateTime? _parseDate(String? iso) =>
      iso == null || iso.isEmpty ? null : DateTime.tryParse(iso)?.toLocal();

  String? _formatTime(String? iso) {
    final date = _parseDate(iso);
    if (date == null) return null;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
