import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';

import '../controllers/live_activity.controller.dart';

/// Live recording sheet — matches the AtomicOS morphism design:
/// header (logo + close), frosted note sheet, and a floating glass recording bar.
class LiveActivityPage extends GetView<LiveActivityController> {
  const LiveActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(
      () => AppPage(
        backgroundColor: colors.background,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildSheet(context)),
            _buildRecordingBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Design.spacing.screenPadding,
        Design.spacing.md,
        Design.spacing.screenPadding,
        Design.spacing.sm,
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Design.icons.atomAdd,
              size: Design.spacing.iconSmall,
              color: colors.primary,
            ),
          ),
          SizedBox(width: Design.spacing.sm),
          Text(
            'AtomicOS',
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _GlassRoundButton(
            icon: Design.icons.close,
            onTap: controller.finishRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Design.spacing.screenPadding),
      child: AppGlassCard(
        padding: EdgeInsets.all(Design.spacing.lg),
        radius: Design.spacing.radiusXLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Design.icons.mic,
                  size: Design.spacing.iconSmall,
                  color: colors.textSecondary,
                ),
                SizedBox(width: Design.spacing.xs),
                Text(
                  'Live meeting',
                  style: context.typo.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(width: Design.spacing.sm),
                Text(
                  controller.isRecording.value
                      ? 'recording in progress'
                      : 'paused',
                  style: context.typo.bodySmall.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
            SizedBox(height: Design.spacing.md),
            Expanded(
              child: TextField(
                controller: controller.noteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Write a Meeting Note…',
                  hintStyle: context.typo.bodyMedium.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                style: context.typo.bodyMedium.copyWith(height: 1.5),
              ),
            ),
            SizedBox(height: Design.spacing.md),
            Row(
              children: [
                Icon(
                  Design.icons.attachment,
                  size: Design.spacing.iconSmall,
                  color: colors.textMuted,
                ),
                SizedBox(width: Design.spacing.xs),
                Text(
                  'Attachments',
                  style: context.typo.labelMedium.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBar(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Design.spacing.screenPadding,
        Design.spacing.md,
        Design.spacing.screenPadding,
        Design.spacing.lg,
      ),
      child: AppGlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: Design.spacing.sm,
        ),
        radius: 999,
        blur: 22,
        child: Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: controller.isRecording.value
                    ? colors.error
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
            Expanded(child: _WaveformBar(active: controller.isRecording.value)),
            SizedBox(width: Design.spacing.md),
            _GlassRoundButton(
              icon: controller.isRecording.value
                  ? Design.icons.pause
                  : Design.icons.play,
              onTap: controller.toggleRecording,
            ),
            SizedBox(width: Design.spacing.sm),
            _EndPill(
              loading: controller.isFinishing.value,
              onTap: controller.finishRecording,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassRoundButton extends StatelessWidget {
  const _GlassRoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: colors.glassStrong,
          shape: BoxShape.circle,
          border: Border.all(color: colors.glassBorder),
        ),
        child: Icon(
          icon,
          size: Design.spacing.iconSmall,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _EndPill extends StatelessWidget {
  const _EndPill({required this.onTap, this.loading = false});

  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: Design.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colors.error,
          borderRadius: BorderRadius.circular(999),
        ),
        child: loading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'End',
                style: context.typo.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _WaveformBar extends StatelessWidget {
  const _WaveformBar({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bars = <double>[10, 16, 22, 14, 26, 30, 18, 16, 22, 14, 10, 8];

    return SizedBox(
      height: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: bars
            .map(
              (height) => Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: active
                      ? colors.primary
                      : colors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
