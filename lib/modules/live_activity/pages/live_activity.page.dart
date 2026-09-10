import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';

import '../controllers/live_activity.controller.dart';

class LiveActivityPage extends GetView<LiveActivityController> {
  const LiveActivityPage({super.key});

  static const _surfaces = <String>['Compact', 'Expanded'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(
      () => AppPage(
        backgroundColor: colors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context),
            SizedBox(height: Design.spacing.lg),
            Text(
              'Live recording',
              style: context.typo.headline2.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              controller.isRecording.value
                  ? 'Capturing audio…'
                  : 'Recording paused',
              style: context.typo.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: Design.spacing.lg),
            _buildStatusHero(context),
            SizedBox(height: Design.spacing.lg),
            _buildSurfacePicker(context),
            SizedBox(height: Design.spacing.xl),
            Expanded(
              child: ListView(
                children: [
                  if (controller.selectedSurface.value == 'Compact') ...[
                    _buildCompactCapsule(context),
                    SizedBox(height: Design.spacing.lg),
                  ],
                  _buildExpandedCard(context),
                  SizedBox(height: Design.spacing.lg),
                  _buildComposerPreview(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _LiveRoundButton(icon: Design.icons.backArrow, onTap: Get.back),
        const Spacer(),
        _LiveRoundButton(
          icon: Design.icons.close,
          onTap: controller.toggleRecording,
        ),
      ],
    );
  }

  Widget _buildSurfacePicker(BuildContext context) {
    final colors = context.colors;

    return Obx(
      () => Row(
        children: _surfaces
            .map(
              (label) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: label == _surfaces.last ? 0 : Design.spacing.sm,
                  ),
                  child: GestureDetector(
                    onTap: () => controller.selectSurface(label),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: Design.spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: controller.selectedSurface.value == label
                            ? colors.primary
                            : colors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: controller.selectedSurface.value == label
                              ? colors.primary
                              : colors.border,
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: context.typo.labelMedium.copyWith(
                          color: controller.selectedSurface.value == label
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

  Widget _buildStatusHero(BuildContext context) {
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
              child: _LiveMetric(
                label: 'State',
                value: controller.isRecording.value ? 'Live' : 'Paused',
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: _LiveMetric(
                label: 'Surface',
                value: controller.selectedSurface.value,
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: _LiveMetric(
                label: 'Elapsed',
                value: controller.formattedElapsed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCapsule(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: Design.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border),
          boxShadow: Design.colors.shadows.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: controller.isRecording.value
                    ? colors.primary
                    : colors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: Design.spacing.xs),
            Text(
              controller.formattedElapsed,
              style: context.typo.caption.copyWith(color: colors.textSecondary),
            ),
            SizedBox(width: Design.spacing.md),
            _WaveformBar(width: 54),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      padding: EdgeInsets.all(Design.spacing.lg),
      borderRadius: Design.spacing.radiusXLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Design.icons.atomAdd,
                  color: colors.primary,
                  size: Design.spacing.iconSmall,
                ),
              ),
              SizedBox(width: Design.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AtomicOS',
                      style: context.typo.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      controller.isRecording.value
                          ? 'Recording in progress'
                          : 'Recording paused',
                      style: context.typo.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Design.spacing.lg),
          _WaveformBar(width: double.infinity),
          SizedBox(height: Design.spacing.lg),
          Row(
            children: [
              Text(
                controller.isRecording.value ? 'Recording' : 'Paused',
                style: context.typo.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              _LiveActionPill(
                icon: Design.icons.pause,
                label: controller.isRecording.value ? 'Pause' : 'Resume',
                onTap: controller.toggleRecording,
              ),
              SizedBox(width: Design.spacing.sm),
              _LiveActionPill(
                icon: Design.icons.stop,
                label: 'End',
                destructive: true,
                onTap: controller.finishRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposerPreview(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      padding: EdgeInsets.all(Design.spacing.lg),
      borderRadius: Design.spacing.radiusXLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Design.icons.note,
                size: Design.spacing.iconSmall,
                color: colors.textSecondary,
              ),
              SizedBox(width: Design.spacing.xs),
              Text(
                'Meeting note',
                style: context.typo.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: Design.spacing.md),
          Text(
            'The transcript and summary are generated when you end the recording.',
            style: context.typo.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
          SizedBox(height: Design.spacing.lg),
          Row(
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: Design.spacing.xs),
              Text(
                controller.formattedElapsed,
                style: context.typo.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(width: Design.spacing.md),
              Expanded(child: _WaveformBar(width: double.infinity)),
              SizedBox(width: Design.spacing.md),
              _LiveActionPill(
                icon: Design.icons.pause,
                label: controller.isRecording.value ? 'Pause' : 'Resume',
                onTap: controller.toggleRecording,
              ),
              SizedBox(width: Design.spacing.sm),
              _LiveActionPill(
                icon: Design.icons.stop,
                label: 'End',
                destructive: true,
                onTap: controller.finishRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveRoundButton extends StatelessWidget {
  const _LiveRoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

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
          color: colors.textSecondary,
          size: Design.spacing.iconSmall,
        ),
      ),
    );
  }
}

class _LiveActionPill extends StatelessWidget {
  const _LiveActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: Design.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: destructive ? colors.error : colors.card,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: Design.spacing.iconSmall,
              color: destructive ? colors.surface : colors.textPrimary,
            ),
            SizedBox(width: Design.spacing.xs),
            Text(
              label,
              style: context.typo.bodySmall.copyWith(
                color: destructive ? colors.surface : colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformBar extends StatelessWidget {
  const _WaveformBar({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bars = <double>[10, 14, 18, 12, 20, 24, 16, 14, 18, 12, 10, 8];

    return SizedBox(
      width: width.isFinite ? width : null,
      height: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: bars
            .map(
              (height) => Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Design.spacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
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
