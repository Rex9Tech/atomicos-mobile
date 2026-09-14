import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';

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
    loadEvents(upcoming: value != 'Month');
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

  /// PUT /v1/calendar/events/:id — rename an item from the planner popup.
  Future<bool> renameEvent(String id, String title) async {
    final clean = title.trim();
    if (clean.isEmpty) return false;
    try {
      final result = await _calendar.renameEvent(id: id, title: clean);
      if (result.success) {
        await loadEvents(upcoming: selectedRange.value != 'Month');
        AppSnackbar.success('Renamed');
        return true;
      }
      AppSnackbar.error(result.error ?? 'Could not rename this item.');
    } catch (error) {
      debugPrint('📅 [CalendarController] Error renaming event: $error');
      AppSnackbar.error('Could not rename this item.');
    }
    return false;
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

  List<CalendarEventModel> get filteredEvents {
    final now = DateTime.now();

    return events.where((event) {
      final start = _parseDate(event.startAt);
      if (start == null) return false;

      switch (selectedRange.value) {
        case 'Month':
          return start.year == now.year && start.month == now.month;
        case 'Day':
        case 'Week':
        default:
          return start.year == now.year &&
              start.month == now.month &&
              start.day == selectedDay.value;
      }
    }).toList()..sort((a, b) {
      final aDate = _parseDate(a.startAt);
      final bDate = _parseDate(b.startAt);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
  }

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
