import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';

import '../controllers/calendar.controller.dart';
import '../data/models/calendar_event.model.dart';

class CalendarPage extends GetView<CalendarController> {
  const CalendarPage({super.key});

  static const _ranges = <String>['Day', 'Week', 'Month'];
  static const _days = <String>['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  String _rangeLabel(String range) {
    switch (range) {
      case 'Day':
        return AppLocales.calendar.rangeDay.tr;
      case 'Week':
        return AppLocales.calendar.rangeWeek.tr;
      case 'Month':
        return AppLocales.calendar.rangeMonth.tr;
    }
    return range;
  }

  String _dayLabel(String day) {
    switch (day) {
      case 'MO':
        return AppLocales.calendar.dayMon.tr;
      case 'TU':
        return AppLocales.calendar.dayTue.tr;
      case 'WE':
        return AppLocales.calendar.dayWed.tr;
      case 'TH':
        return AppLocales.calendar.dayThu.tr;
      case 'FR':
        return AppLocales.calendar.dayFri.tr;
      case 'SA':
        return AppLocales.calendar.daySat.tr;
      case 'SU':
        return AppLocales.calendar.daySun.tr;
    }
    return day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppPage(
      backgroundColor: colors.background,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context),
            SizedBox(height: Design.spacing.lg),
            Text(
              AppLocales.calendar.pageHeader.tr,
              style: context.typo.headline2.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              AppLocales.calendar.headerSub.tr,
              style: context.typo.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: Design.spacing.lg),
            _buildScheduleHero(context),
            SizedBox(height: Design.spacing.lg),
            _buildRangePicker(context),
            SizedBox(height: Design.spacing.lg),
            _buildWeekHeader(context),
            SizedBox(height: Design.spacing.md),
            _buildCalendarGrid(context),
            SizedBox(height: Design.spacing.lg),
            _buildAgendaCard(context),
            SizedBox(height: Design.spacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        _RoundIconButton(icon: Design.icons.backArrow, onTap: Get.back),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Design.spacing.md,
            vertical: Design.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Design.icons.calendar,
                size: Design.spacing.iconSmall,
                color: colors.primary,
              ),
              SizedBox(width: Design.spacing.xs),
              Text(
                AppLocales.calendar.title.tr,
                style: context.typo.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangePicker(BuildContext context) {
    final colors = context.colors;

    return Obx(
      () => Row(
        children: _ranges
            .map(
              (label) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: label == _ranges.last ? 0 : Design.spacing.sm,
                  ),
                  child: GestureDetector(
                    onTap: () => controller.selectRange(label),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: Design.spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: controller.selectedRange.value == label
                            ? colors.primary
                            : colors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: controller.selectedRange.value == label
                              ? colors.primary
                              : colors.border,
                        ),
                      ),
                      child: Text(
                        _rangeLabel(label),
                        textAlign: TextAlign.center,
                        style: context.typo.labelMedium.copyWith(
                          color: controller.selectedRange.value == label
                              ? colors.background
                              : colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildScheduleHero(BuildContext context) {
    final colors = context.colors;

    return Obx(
      () => Container(
        padding: EdgeInsets.all(Design.spacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary.withValues(alpha: 0.16), colors.surface],
          ),
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _CalendarMetric(
                label: AppLocales.calendar.metricVisible.tr,
                value: '${controller.filteredEvents.length}',
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: _CalendarMetric(
                label: AppLocales.calendar.metricRange.tr,
                value: controller.selectedRange.value,
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: _CalendarMetric(
                label: AppLocales.calendar.metricDay.tr,
                value: '${controller.selectedDay.value}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Design.icons.backArrow,
            size: 14,
            onTap: () {},
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  MaterialLocalizations.of(context).formatMonthYear(DateTime.now()),
                  style: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: Design.spacing.xs),
                Text(
                  '5 - 11',
                  style: context.typo.headline3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _RoundIconButton(
            icon: Design.icons.rightArrow,
            size: 14,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final colors = context.colors;
    final days = List<int>.generate(35, (index) => index + 1);

    return AppGlassCard(
      padding: EdgeInsets.all(Design.spacing.lg),
      radius: Design.spacing.radiusXLarge,
      child: Column(
        children: [
          Row(
            children: _days
                .map(
                  (label) => Expanded(
                    child: Text(
                      _dayLabel(label),
                      textAlign: TextAlign.center,
                      style: context.typo.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: Design.spacing.md),
          Obx(
            () => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              mainAxisSpacing: Design.spacing.sm,
              crossAxisSpacing: Design.spacing.sm,
              childAspectRatio: 0.95,
              children: days.map((day) {
                final isActive = controller.hasEventOnDay(day);
                final isSelected = controller.selectedDay.value == day;

                return GestureDetector(
                  onTap: () => controller.selectDay(day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : isActive
                          ? colors.primary.withValues(alpha: 0.14)
                          : colors.card,
                      borderRadius: BorderRadius.circular(
                        Design.spacing.radiusLarge,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : isActive
                            ? colors.primary.withValues(alpha: 0.24)
                            : colors.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: context.typo.labelLarge.copyWith(
                            color: isSelected
                                ? colors.onPrimary
                                : colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: Design.spacing.xs),
                        Container(
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isSelected
                                      ? colors.onPrimary
                                      : colors.primary)
                                : colors.card.withValues(alpha: 0),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaCard(BuildContext context) {
    final colors = context.colors;

    return Obx(
      () => AppGlassCard(
        padding: EdgeInsets.all(Design.spacing.lg),
        radius: Design.spacing.radiusXLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  controller.selectedRange.value == 'Month'
                      ? AppLocales.calendar.monthSchedule.tr
                      : AppLocales.calendar.scheduleFor.trParams(
                          {'day': '${controller.selectedDay.value}'}),
                  style: context.typo.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: AppRoutes.toLiveActivity,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Design.spacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppLocales.calendar.openLiveView.tr,
                      style: context.typo.bodySmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Design.spacing.md),
            _buildAgendaList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaList(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      if (controller.isLoadingEvents.value) {
        return _agendaStatus(context, const CircularProgressIndicator());
      }
      if (controller.hasEventsError.value) {
        return _agendaStatus(
          context,
          Text(
            AppLocales.calendar.scheduleLoadFailed.tr,
            style: context.typo.bodySmall.copyWith(color: colors.textSecondary),
          ),
        );
      }
      final visibleEvents = controller.filteredEvents;

      if (visibleEvents.isEmpty) {
        return _agendaStatus(
          context,
          Text(
            AppLocales.calendar.noEvents.tr,
            style: context.typo.bodySmall.copyWith(color: colors.textSecondary),
          ),
        );
      }

      return Column(
        children: [
          for (var i = 0; i < visibleEvents.length; i++) ...[
            if (i > 0) SizedBox(height: Design.spacing.md),
            _AgendaRow(
              time: controller.eventTime(visibleEvents[i]) ?? '--:--',
              title: visibleEvents[i].title,
              subtitle: (visibleEvents[i].description?.isNotEmpty ?? false)
                  ? visibleEvents[i].description!
                  : AppLocales.calendar.scheduled.tr,
              onTap: AppRoutes.toLiveActivity,
              onMore: () => _showEventMenu(context, visibleEvents[i]),
            ),
          ],
        ],
      );
    });
  }

  Widget _agendaStatus(BuildContext context, Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Design.spacing.lg),
      child: Center(child: child),
    );
  }

  // ===== Item popup: rename / open =====

  void _showEventMenu(BuildContext context, CalendarEventModel event) {
    Get.bottomSheet<void>(
      Container(
        margin: EdgeInsets.all(Design.spacing.sm),
        padding: EdgeInsets.all(Design.spacing.lg),
        decoration: BoxDecoration(
          color: context.colors.neumo,
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
          boxShadow: context.colors.neumoShadow,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.typo.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Design.spacing.lg),
              _SheetAction(
                icon: Design.icons.edit,
                label: AppLocales.common.rename.tr,
                onTap: () {
                  Get.back();
                  _promptRename(context, event);
                },
              ),
              SizedBox(height: Design.spacing.sm),
              _SheetAction(
                icon: Design.icons.play,
                label: AppLocales.calendar.openLiveView.tr,
                onTap: () {
                  Get.back();
                  AppRoutes.toLiveActivity();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptRename(
    BuildContext context,
    CalendarEventModel event,
  ) async {
    final textController = TextEditingController(text: event.title);
    final next = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        ),
        title: Text(
          AppLocales.common.rename.tr,
          style: context.typo.headline4.copyWith(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Atom name'),
          onSubmitted: (value) => Get.back(result: value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocales.common.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: textController.text.trim()),
            child: Text(AppLocales.common.save.tr),
          ),
        ],
      ),
    );

    final clean = next?.trim() ?? '';
    if (clean.isEmpty || clean == event.title) return;
    await controller.renameEvent(event.id, clean);
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Design.spacing.md),
        decoration: BoxDecoration(
          color: colors.neumo,
          borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
          boxShadow: colors.neumoShadowSoft,
        ),
        child: Row(
          children: [
            Icon(icon, size: Design.spacing.iconSmall, color: colors.primary),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: Text(
                label,
                style: context.typo.labelMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Design.icons.rightArrow,
              size: Design.spacing.iconSmall,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.size});

  final IconData icon;
  final VoidCallback onTap;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: colors.neumo,
          shape: BoxShape.circle,
          boxShadow: colors.neumoShadowSoft,
        ),
        child: Icon(
          icon,
          size: size ?? Design.spacing.iconSmall,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onMore,
  });

  final String time;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppGlassCard(
      onTap: onTap,
      padding: EdgeInsets.all(Design.spacing.md),
      radius: Design.spacing.radiusLarge,
      child: Row(
        children: [
          Container(
            width: 56,
            padding: EdgeInsets.symmetric(vertical: Design.spacing.sm),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: context.typo.bodySmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: Design.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typo.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Design.spacing.xs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Design.spacing.sm),
          GestureDetector(
            onTap: onMore,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(Design.spacing.xs),
              child: Icon(
                Design.icons.more,
                size: Design.spacing.iconSmall,
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarMetric extends StatelessWidget {
  const _CalendarMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: EdgeInsets.all(Design.spacing.md),
      radius: Design.spacing.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Design.spacing.xs),
          Text(
            label,
            style: context.typo.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
