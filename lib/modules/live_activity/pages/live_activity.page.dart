import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';

import '../controllers/live_activity.controller.dart';

/// Live recording sheet — matches the AtomicOS morphism design:
/// header (logo + close), frosted sheet with the live transcript, and a
/// floating glass recording bar.
class LiveActivityPage extends GetView<LiveActivityController> {
  const LiveActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmFinish(context);
      },
      child: Obx(
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
      ),
    );
  }

  /// Guards End / system-Back while a session is live — testers stopped
  /// recordings by accident and asked for a warning.
  Future<void> _confirmFinish(BuildContext context) async {
    if (controller.isFinishing.value) return;

    final hasSession =
        controller.isRecording.value ||
        (controller.recordingId.value ?? '').isNotEmpty;
    if (!hasSession) {
      Get.back();
      return;
    }

    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppLocales.recording.endTitle.tr,
      message: AppLocales.recording.endMessage.tr,
      confirmLabel: AppLocales.recording.endConfirm.tr,
      confirmColor: context.colors.error,
      cancelColor: context.colors.textSecondary,
    );
    if (confirmed) {
      await controller.finishRecording();
    }
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
            onTap: () => _confirmFinish(context),
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
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          AppLocales.recording.liveMeeting.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typo.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: Design.spacing.sm),
                      Text(
                        controller.isRecording.value ? 'recording' : 'paused',
                        style: context.typo.bodySmall.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Design.spacing.xs),
                Obx(
                  () => Text(
                    controller.activeLanguageLabel,
                    style: context.typo.labelMedium.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
                SizedBox(width: Design.spacing.xs),
                _LiveBadge(active: controller.isTranscriptLive.value),
              ],
            ),
            SizedBox(height: Design.spacing.md),
            Expanded(child: _LiveTranscriptPanel(controller: controller)),
            SizedBox(height: Design.spacing.md),
            Row(
              children: [
                Icon(
                  Design.icons.note,
                  size: Design.spacing.iconSmall,
                  color: colors.textMuted,
                ),
                SizedBox(width: Design.spacing.xs),
                Text(
                  AppLocales.atom.note.tr,
                  style: context.typo.labelMedium.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
            SizedBox(height: Design.spacing.xs),
            TextField(
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              controller: controller.noteController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                hintText: AppLocales.recording.noteFieldHint.tr,
                hintStyle: context.typo.bodyMedium.copyWith(
                  color: colors.textMuted,
                ),
              ),
              style: context.typo.bodyMedium.copyWith(height: 1.5),
            ),
            SizedBox(height: Design.spacing.sm),
            Row(
              children: [
                Icon(
                  Design.icons.attachment,
                  size: Design.spacing.iconSmall,
                  color: colors.textMuted,
                ),
                SizedBox(width: Design.spacing.xs),
                Text(
                  AppLocales.ai.attachments.tr,
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
              onTap: () => _confirmFinish(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable panel that streams the live transcript and keeps the newest
/// text in view as it arrives.
class _LiveTranscriptPanel extends StatefulWidget {
  const _LiveTranscriptPanel({required this.controller});

  final LiveActivityController controller;

  @override
  State<_LiveTranscriptPanel> createState() => _LiveTranscriptPanelState();
}

class _LiveTranscriptPanelState extends State<_LiveTranscriptPanel> {
  final ScrollController _scroll = ScrollController();
  Worker? _transcriptWorker;

  @override
  void initState() {
    super.initState();
    _transcriptWorker = ever<String>(widget.controller.liveTranscript, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _transcriptWorker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // The transcript streams into a well sunk into the sheet, so the text
    // reads as content the sheet holds rather than another card on top of it.
    return AppNeumoSurface(
      depth: ENeumoDepth.inset,
      width: double.infinity,
      padding: EdgeInsets.all(Design.spacing.md),
      child: Obx(() {
        final text = widget.controller.liveTranscript.value.trim();
        final notice = widget.controller.transcriptNotice.value;

        return SingleChildScrollView(
          controller: _scroll,
          child: text.isEmpty
              ? Text(
                  notice ?? AppLocales.recording.transcriptPlaceholder.tr,
                  style: context.typo.bodyMedium.copyWith(
                    color: colors.textMuted,
                    height: 1.5,
                  ),
                )
              : Text(
                  text,
                  style: context.typo.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    height: 1.5,
                  ),
                ),
        );
      }),
    );
  }
}

/// Small pill that shows whether the live transcript is streaming.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.primary : colors.textMuted;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Design.spacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            active
                ? AppLocales.recording.badgeLive.tr
                : AppLocales.recording.badgeOff.tr,
            style: context.typo.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
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
      child: AppNeumoSurface(
        circle: true,
        soft: true,
        width: 36,
        height: 36,
        padding: EdgeInsets.zero,
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
                AppLocales.recording.end.tr,
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
