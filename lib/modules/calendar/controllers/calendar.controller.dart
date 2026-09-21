import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';

import '../data/models/calendar_event.model.dart';
import '../services/calendar.service.dart';

class CalendarController extends GetxController {
  final CalendarService _calendar = Get.find<CalendarService>();

  final RxString selectedRange = 'Month'.obs;

  /// Day of [viewMonth] the planner is focused on.
  final RxInt selectedDay = DateTime.now().day.obs;

  /// First day of the month the grid is showing.
  final Rx<DateTime> viewMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;

  final RxList<CalendarEventModel> events = <CalendarEventModel>[].obs;
  final RxBool isLoadingEvents = false.obs;
  final RxBool hasEventsError = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  // ===== Selection & navigation =====

  void selectRange(String value) => selectedRange.value = value;

  void selectDay(int value) => selectedDay.value = value;

  void goToPreviousMonth() => _shiftMonth(-1);

  void goToNextMonth() => _shiftMonth(1);

  void _shiftMonth(int delta) {
    final current = viewMonth.value;
    viewMonth.value = DateTime(current.year, current.month + delta);

    final now = DateTime.now();
    final onCurrentMonth =
        viewMonth.value.year == now.year && viewMonth.value.month == now.month;
    selectedDay.value = onCurrentMonth ? now.day : 1;
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    final m = viewMonth.value;
    return m.year == now.year && m.month == now.month;
  }

  /// The concrete date [selectedDay] points at inside [viewMonth].
  DateTime get selectedDate =>
      DateTime(viewMonth.value.year, viewMonth.value.month, selectedDay.value);

  /// Monday of the week containing [selectedDate].
  DateTime get weekStart {
    final d = selectedDate;
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  /// Sunday of the week containing [selectedDate].
  DateTime get weekEnd =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

  // ===== Grid math =====

  int get daysInMonth =>
      DateTime(viewMonth.value.year, viewMonth.value.month + 1, 0).day;

  /// Empty cells before day 1 in a Monday-first grid.
  int get leadingBlanks =>
      (DateTime(viewMonth.value.year, viewMonth.value.month, 1).weekday + 6) %
      7;

  bool isToday(int day) {
    final now = DateTime.now();
    final m = viewMonth.value;
    return m.year == now.year && m.month == now.month && day == now.day;
  }

  // ===== Data =====

  Future<void> loadEvents() async {
    isLoadingEvents.value = true;
    hasEventsError.value = false;
    try {
      final result = await _calendar.getEvents(limit: 100);
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
        await loadEvents();
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

  // ===== Event helpers =====

  DateTime? eventStart(CalendarEventModel event) => _parseDate(event.startAt);

  DateTime? eventEnd(CalendarEventModel event) => _parseDate(event.endAt);

  /// HH:mm start label for the time pill.
  String? eventTime(CalendarEventModel event) => _formatTime(event.startAt);

  /// "HH:mm – HH:mm" (or just the start time) for agenda meta lines.
  String? eventTimeRange(CalendarEventModel event) {
    final start = _formatTime(event.startAt);
    if (start == null) return null;
    final end = _formatTime(event.endAt);
    return end == null ? start : '$start – $end';
  }

  /// True when any event starts on [day] of the month in view — drives the
  /// calendar-grid highlight dots.
  bool hasEventOnDay(int day) {
    final m = viewMonth.value;
    return events.any((event) {
      final start = _parseDate(event.startAt);
      return start != null &&
          start.year == m.year &&
          start.month == m.month &&
          start.day == day;
    });
  }

  /// Events starting inside the shown month.
  List<CalendarEventModel> get monthEvents {
    final m = viewMonth.value;
    return _sorted(
      events.where((event) {
        final start = _parseDate(event.startAt);
        return start != null && start.year == m.year && start.month == m.month;
      }),
    );
  }

  List<CalendarEventModel> get filteredEvents {
    switch (selectedRange.value) {
      case 'Day':
        final day = selectedDate;
        return _sorted(
          events.where((event) {
            final start = _parseDate(event.startAt);
            return start != null && _isSameDay(start, day);
          }),
        );
      case 'Week':
        final from = weekStart;
        final to = DateTime(
          weekEnd.year,
          weekEnd.month,
          weekEnd.day,
          23,
          59,
          59,
        );
        return _sorted(
          events.where((event) {
            final start = _parseDate(event.startAt);
            return start != null && !start.isBefore(from) && !start.isAfter(to);
          }),
        );
      case 'Month':
      default:
        return monthEvents;
    }
  }

  List<CalendarEventModel> _sorted(Iterable<CalendarEventModel> source) {
    final list = source.toList()
      ..sort((a, b) {
        final aDate = _parseDate(a.startAt);
        final bDate = _parseDate(b.startAt);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
    return list;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
