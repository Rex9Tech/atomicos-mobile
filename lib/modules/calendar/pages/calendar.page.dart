import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(context),
          SizedBox(height: Design.spacing.lg),
          Text(
            'Ciao, Damir!',
            style: context.typo.headline2.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: Design.spacing.xs),
          Text(
            'Review the week and jump into live sessions.',
            style: context.typo.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: Design.spacing.lg),
          _buildRangePicker(context),
          SizedBox(height: Design.spacing.lg),
          _buildWeekHeader(context),
          SizedBox(height: Design.spacing.md),
          _buildCalendarGrid(context),
          SizedBox(height: Design.spacing.lg),
          _buildAgendaCard(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        _RoundIconButton(
          icon: Design.icons.backArrow,
          onTap: Get.back,
        ),
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
                'Planner',
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
    final highlighted = <int>{6, 7, 9, 10, 13, 18, 22, 26, 28, 31};

    return Container(
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        border: Border.all(color: colors.border),
      ),
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
              childAspectRatio: 0.72,
              children: days.map((day) {
                final isActive = highlighted.contains(day);
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
                                ? colors.background
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
                                      ? colors.background
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

    return Container(
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today schedule',
                style: context.typo.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: AppRoutes.toLiveActivity,
                child: Text(
                  'Open live view',
                  style: context.typo.bodySmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Design.spacing.md),
          const _AgendaRow(
            time: '09:00',
            title: 'Daily sync with Product',
            subtitle: 'Zoom · 3 speakers',
          ),
          SizedBox(height: Design.spacing.md),
          const _AgendaRow(
            time: '11:30',
            title: 'Myanmar research review',
            subtitle: 'Google Meet · 4 speakers',
          ),
          SizedBox(height: Design.spacing.md),
          const _AgendaRow(
            time: '15:00',
            title: 'Weekly launch planning',
            subtitle: 'Slack huddle · 2 speakers',
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.size,
  });

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
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
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
  });

  final String time;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Design.spacing.xs),
              Text(
                subtitle,
                style: context.typo.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
