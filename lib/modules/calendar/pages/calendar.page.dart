import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';

import '../controllers/calendar.controller.dart';

class CalendarPage extends GetView<CalendarController> {
  const CalendarPage({super.key});

  static const _ranges = <String>['Day', 'Week', 'Month'];
  static const _days = <String>['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

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
              'Calendar',
              style: context.typo.headline2.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              'Review upcoming sessions, then jump straight into the live workspace.',
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
                        label,
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
                label: 'Visible',
                value: '${controller.filteredEvents.length}',
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: _CalendarMetric(
                label: 'Range',
                value: controller.selectedRange.value,
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: _CalendarMetric(
                label: 'Day',
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
                  'August',
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
                      label,
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
                      ? 'Month schedule'
                      : 'Schedule for ${controller.selectedDay.value}',
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
                      'Open live view',
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
          color: colors.glass,
          shape: BoxShape.circle,
          border: Border.all(color: colors.glassBorder),
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
  });

  final String time;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
          Icon(
            Design.icons.rightArrow,
            size: Design.spacing.iconSmall,
            color: colors.textMuted,
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
