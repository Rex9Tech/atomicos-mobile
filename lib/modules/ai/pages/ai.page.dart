import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';

import '../ai.dart';

class AiPage extends GetView<AiController> {
  const AiPage({super.key});

  static const _tabs = <String>['Summary', 'Transcript', 'Note', 'Assets'];
  static const _askFilters = <String>['All', 'AtomOS', 'New', 'Personal'];
  static const _askSources = <String>['Camera', 'Files', 'Add Atom'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isAskMode) {
        return AppPage(
          backgroundColor: context.colors.background,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Design.spacing.screenPadding,
                    Design.spacing.md,
                    Design.spacing.screenPadding,
                    0,
                  ),
                  child: SingleChildScrollView(
                    child: _buildAskFlow(context),
                  ),
                ),
              ),
              _buildAskComposer(context),
            ],
          ),
        );
      }

      if (controller.isMeetingWorkspace) {
        return AppPage(
          backgroundColor: context.colors.background,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Design.spacing.screenPadding,
                  Design.spacing.md,
                  Design.spacing.screenPadding,
                  0,
                ),
                child: _buildMeetingWorkspaceHeader(context),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Design.spacing.screenPadding,
                    Design.spacing.lg,
                    Design.spacing.screenPadding,
                    0,
                  ),
                  child: _buildMeetingWorkspaceCanvas(context),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Design.spacing.screenPadding,
                  Design.spacing.md,
                  Design.spacing.screenPadding,
                  Design.spacing.screenPadding,
                ),
                child: SafeArea(
                  top: false,
                  child: _buildRecordingDock(context),
                ),
              ),
            ],
          ),
        );
      }

      return DefaultTabController(
        length: _tabs.length,
        child: AppPage(
          backgroundColor: context.colors.background,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Design.spacing.screenPadding,
                  Design.spacing.md,
                  Design.spacing.screenPadding,
                  0,
                ),
                child: Column(
                  children: [
                    _buildDetailsTopBar(context),
                    SizedBox(height: Design.spacing.lg),
                    _buildAudioCard(context),
                    SizedBox(height: Design.spacing.lg),
                    _buildTabs(context),
                    SizedBox(height: Design.spacing.lg),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Design.spacing.screenPadding,
                  ),
                  child: _showRecordingPreviewState
                      ? _buildRecordingCanvas(context)
                      : _buildTabContent(context),
                ),
              ),
              _buildDetailsComposer(context),
            ],
          ),
        ),
      );
    });
  }

  bool get _showRecordingPreviewState => controller.hasRecordingPreview;

  Widget _buildMeetingWorkspaceHeader(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Design.icons.atomAdd,
              size: Design.spacing.iconSmall,
              color: colors.textSecondary,
            ),
            SizedBox(width: Design.spacing.sm),
            Text(
              'AtomicOS',
              style: context.typo.labelLarge.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: Get.back,
          child: Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Design.icons.close,
              size: 16,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingWorkspaceCanvas(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecordingStagePicker(context),
          SizedBox(height: Design.spacing.md),
          Wrap(
            spacing: Design.spacing.xs,
            runSpacing: Design.spacing.xs,
            children: const [
              _MeetingChip(label: 'SLACK'),
              _MeetingChip(label: 'Japanese restricted'),
            ],
          ),
          SizedBox(height: Design.spacing.sm),
          Text(
            'Write a Meeting Note...',
            style: context.typo.bodyLarge.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Design.spacing.sm),
          Text(
            '@ Marketing',
            style: context.typo.bodySmall.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: Design.spacing.lg),
          Expanded(
            child: controller.isRecordingProcessing
                ? _buildRecordingStatusPanel(
                    context,
                    title: 'Processing meeting',
                    subtitle:
                        'AtomicOS is building summary, transcript, and actions from the captured audio.',
                    icon: Design.icons.sparkles,
                  )
                : controller.isRecordingComplete
                ? _buildRecordingStatusPanel(
                    context,
                    title: 'Meeting ready',
                    subtitle:
                        'Preview generated outputs, then jump into the full details view.',
                    icon: Design.icons.success,
                  )
                : TextField(
                    controller: controller.textController,
                    onChanged: controller.updateAskDraft,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixIconConstraints: const BoxConstraints(),
                    ),
                    style: context.typo.bodyMedium.copyWith(height: 1.45),
                  ),
          ),
          if (controller.isRecordingPaused) ...[
            SizedBox(height: Design.spacing.md),
            _buildRecordingStatusPanel(
              context,
              title: 'Recording paused',
              subtitle:
                  'Notes stay editable while the mic is paused. Resume when the meeting continues.',
              icon: Design.icons.pause,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAskFlow(BuildContext context) {
    if (controller.showAskResultPreview) {
      return _buildAskResultPreview(context);
    }

    if (controller.showAskSourceResults) {
      return _buildAskSourceResults(context);
    }

    return _buildAskLanding(context);
  }

  Widget _buildAskLanding(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAskTopBar(context),
        SizedBox(height: Design.spacing.xxl),
        Text(
          'Ask AtomicOS',
          style: context.typo.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.xs),
        Text(
          'Start with a question or pick a shortcut.',
          style: context.typo.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: Design.spacing.xxl),
        Obx(() {
          if (!controller.showAskAttachmentMenu) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.only(bottom: Design.spacing.md),
            child: Row(
              children: _askSources
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: entry.key == _askSources.length - 1
                              ? 0
                              : Design.spacing.sm,
                        ),
                        child: _AskSourceCard(
                          icon: _iconForSource(entry.value),
                          label: entry.value,
                          onTap: () =>
                              controller.selectAskAttachment(entry.value),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }),
        ..._buildAskActionItems().map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: Design.spacing.sm),
            child: _AskActionRow(
              icon: item.icon,
              label: item.label,
              onTap: () => controller.applyPromptSuggestion(item.label),
            ),
          ),
        ),
        SizedBox(height: Design.spacing.lg),
        Obx(() {
          final preview = controller.askAttachmentPreview.value;
          if (preview == null) {
            return const SizedBox.shrink();
          }

          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 116,
              margin: EdgeInsets.only(bottom: Design.spacing.md),
              padding: EdgeInsets.all(Design.spacing.sm),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(
                        Design.spacing.radiusMedium,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Design.icons.folder,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: Design.spacing.sm),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAskSourceResults(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAskTopBar(context),
        SizedBox(height: Design.spacing.xxl),
        Text(
          'Choose context',
          style: context.typo.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.xs),
        Text(
          'Choose an atom to use as context.',
          style: context.typo.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: Design.spacing.xl),
        Container(
          padding: EdgeInsets.all(Design.spacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Design.spacing.md,
                  vertical: Design.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(
                    Design.spacing.radiusLarge,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Design.icons.search,
                      size: Design.spacing.iconSmall,
                      color: colors.textMuted,
                    ),
                    SizedBox(width: Design.spacing.sm),
                    Expanded(
                      child: Text(
                        'Search...',
                        style: context.typo.bodySmall.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Design.spacing.md),
              Wrap(
                spacing: Design.spacing.xs,
                runSpacing: Design.spacing.xs,
                children: _askFilters
                    .map(
                      (label) => _AskFilterChip(
                        label: label,
                        selected: label == 'All',
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: Design.spacing.md),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: Design.spacing.lg),
                child: Text(
                  'Your atoms will appear here to use as context.',
                  textAlign: TextAlign.center,
                  style: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: Design.spacing.sm),
              Row(
                children: [
                  _BottomMiniButton(
                    icon: Design.icons.backArrow,
                    onTap: controller.closeAskAttachmentMenu,
                  ),
                  SizedBox(width: Design.spacing.sm),
                  _BottomMiniButton(
                    icon: Design.icons.sparkles,
                    onTap: controller.closeAskAttachmentMenu,
                    background: colors.primary,
                    foreground: colors.background,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAskResultPreview(BuildContext context) {
    final colors = context.colors;
    final submittedPrompt =
        controller.askSubmittedPrompt.value ?? controller.askDraft.value;
    final sourceLabel = controller.askSelectedSource.value ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAskTopBar(context),
        SizedBox(height: Design.spacing.xl),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: EdgeInsets.symmetric(
              horizontal: Design.spacing.md,
              vertical: Design.spacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
              border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
            ),
            child: Text(
              submittedPrompt.isEmpty ? '' : submittedPrompt,
              style: context.typo.bodySmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Design.spacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              sourceLabel,
              style: context.typo.labelMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: Design.spacing.lg),
        Container(
          padding: EdgeInsets.all(Design.spacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: _buildAskActionItems()
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: Design.spacing.sm),
                          child: _AskActionRow(
                            icon: item.icon,
                            label: item.label,
                            compact: true,
                            onTap: () => controller.runAskAction(item.label),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              SizedBox(width: Design.spacing.md),
              const _PreviewDocumentCard(),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.lg),
        Obx(() {
          final lines = controller.askActionLines;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(Design.spacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Design.spacing.md),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(
                      Design.spacing.radiusLarge,
                    ),
                  ),
                  child: controller.isRunningAskAction.value
                      ? const Center(child: CircularProgressIndicator())
                      : _buildActionResultContent(context),
                ),
                SizedBox(height: Design.spacing.md),
                Text(
                  controller.askActionTitle.value,
                  style: context.typo.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Design.spacing.xs),
                Text(
                  'Live result returned by the selected AI action.',
                  style: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: Design.spacing.md),
                Wrap(
                  spacing: Design.spacing.sm,
                  runSpacing: Design.spacing.sm,
                  children: [
                    _MiniResultChip(label: '${lines.length} lines'),
                    _MiniResultChip(label: sourceLabel),
                    _MiniResultChip(
                      label: submittedPrompt.isEmpty ? 'Draft' : 'Prompt',
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        SizedBox(height: Design.spacing.lg),
        Obx(() {
          final lines = controller.askActionLines.skip(3).take(3).toList();
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(Design.spacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generated actions',
                  style: context.typo.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Design.spacing.md),
                if (controller.isRunningAskAction.value)
                  const Center(child: CircularProgressIndicator())
                else if (lines.isEmpty)
                  _ActionBullet(
                    text:
                        'Additional structured steps will appear here when the response includes them.',
                  )
                else
                  ...lines.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == lines.length - 1 ? 0 : 8,
                      ),
                      child: _ActionBullet(text: entry.value),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionResultContent(BuildContext context) {
    final data = controller.askActionData.value;
    final lines = controller.askActionLines;

    if (data != null) {
      final decisions = data['decisions'];
      final tasks = data['tasks'];
      final report = data['report'];

      if (decisions is List && decisions.isNotEmpty) {
        return _buildDecisionList(context, decisions);
      }
      if (tasks is List && tasks.isNotEmpty) {
        return _buildTaskList(context, tasks);
      }
      if (report is Map && report.isNotEmpty) {
        return _buildReportSections(context, report);
      }
    }

    return Text(
      lines.isEmpty
          ? 'Run an action to generate a backend response preview.'
          : lines.take(3).join('\n\n'),
      style: context.typo.bodyMedium.copyWith(height: 1.45),
    );
  }

  Widget _buildDecisionList(BuildContext context, List<dynamic> decisions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: decisions.whereType<Map>().map((d) {
        final title = d['title']?.toString() ?? '';
        final detail = d['detail']?.toString() ?? '';
        return Padding(
          padding: EdgeInsets.only(bottom: Design.spacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Design.icons.bolt, size: 16, color: context.colors.primary),
              SizedBox(width: Design.spacing.sm),
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
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        style: context.typo.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskList(BuildContext context, List<dynamic> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tasks.whereType<Map>().map((t) {
        final title = t['title']?.toString() ?? '';
        return Padding(
          padding: EdgeInsets.only(bottom: Design.spacing.sm),
          child: Row(
            children: [
              Icon(Design.icons.check, size: 16, color: context.colors.primary),
              SizedBox(width: Design.spacing.sm),
              Expanded(child: Text(title, style: context.typo.bodyMedium)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportSections(BuildContext context, Map report) {
    final summary = report['summary']?.toString() ?? '';
    final keyPoints = report['key_points'];
    final actionItems = report['action_items'];
    final risks = report['risks'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.isNotEmpty)
          Text(
            summary,
            style: context.typo.bodyMedium.copyWith(height: 1.45),
          ),
        if (keyPoints is List && keyPoints.isNotEmpty) ...[
          SizedBox(height: Design.spacing.md),
          _reportSection(context, 'Key points', keyPoints),
        ],
        if (actionItems is List && actionItems.isNotEmpty) ...[
          SizedBox(height: Design.spacing.md),
          _reportSection(context, 'Action items', actionItems),
        ],
        if (risks is List && risks.isNotEmpty) ...[
          SizedBox(height: Design.spacing.md),
          _reportSection(context, 'Risks', risks),
        ],
      ],
    );
  }

  Widget _reportSection(
    BuildContext context,
    String title,
    List<dynamic> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.typo.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: Design.spacing.xs),
        ...items.map(
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${i.toString()}',
              style: context.typo.bodySmall.copyWith(height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAskTopBar(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Design.icons.backArrow, onTap: Get.back),
        Expanded(
          child: Text(
            'Ask AtomicOS',
            textAlign: TextAlign.center,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _CircleIconButton(
          icon: Design.icons.clock,
          onTap: () => _showRoomsBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildAskComposer(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        Design.spacing.screenPadding,
        Design.spacing.sm,
        Design.spacing.screenPadding,
        Design.spacing.screenPadding,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final chipText = _askChipText();
              if (chipText == null) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: Design.spacing.sm),
                padding: EdgeInsets.symmetric(
                  horizontal: Design.spacing.md,
                  vertical: Design.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(
                    Design.spacing.radiusLarge,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'SUMM.',
                      style: context.typo.labelMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: Design.spacing.xs),
                    Expanded(
                      child: Text(
                        chipText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typo.bodySmall,
                      ),
                    ),
                    if (controller.askAttachmentPreview.value != null) ...[
                      SizedBox(width: Design.spacing.sm),
                      GestureDetector(
                        onTap: controller.clearAskAttachmentPreview,
                        child: Icon(
                          Design.icons.close,
                          size: Design.spacing.iconSmall,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Design.spacing.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(
                  Design.spacing.radiusXLarge,
                ),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: controller.toggleAskAttachmentMenu,
                    child: Icon(
                      Design.icons.add,
                      size: Design.spacing.iconMedium,
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(width: Design.spacing.sm),
                  Expanded(
                    child: TextField(
                      controller: controller.textController,
                      onChanged: controller.updateAskDraft,
                      minLines: 1,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Ask Atomic...',
                      ),
                    ),
                  ),
                  SizedBox(width: Design.spacing.sm),
                  GestureDetector(
                    onTap: controller.handleSend,
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Design.icons.send,
                        size: 12,
                        color: colors.background,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _askChipText() {
    final submitted = controller.askSubmittedPrompt.value?.trim();
    if (submitted != null && submitted.isNotEmpty) {
      return submitted;
    }

    final draft = controller.askDraft.value.trim();
    if (draft.isNotEmpty) {
      return draft;
    }

    return null;
  }

  List<_AskActionItem> _buildAskActionItems() {
    return [
      _AskActionItem(icon: Design.icons.bolt, label: 'Summary'),
      _AskActionItem(icon: Design.icons.route, label: 'Decisions'),
      _AskActionItem(icon: Design.icons.sparkles, label: 'Fusion with'),
      _AskActionItem(icon: Design.icons.task, label: 'Generate tasks'),
      _AskActionItem(
        icon: Design.icons.report,
        label: 'Generate analytic report',
      ),
    ];
  }

  IconData _iconForSource(String source) {
    switch (source) {
      case 'Camera':
        return Design.icons.camera;
      case 'Files':
        return Design.icons.folder;
      case 'Add Atom':
        return Design.icons.atomAdd;
      default:
        return Design.icons.add;
    }
  }

  Widget _buildDetailsTopBar(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Design.icons.backArrow, onTap: Get.back),
        Expanded(
          child: Text(
            'Details',
            textAlign: TextAlign.center,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _CircleIconButton(
          icon: Design.icons.more,
          onTap: () => _showRoomsBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildAudioCard(BuildContext context) {
    final colors = context.colors;
    final hasMessages = controller.messages.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: hasMessages ? 0.32 : 0.0,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: colors.card,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
          SizedBox(height: Design.spacing.md),
          Row(
            children: [
              _MiniControl(icon: Design.icons.play, active: true),
              SizedBox(width: Design.spacing.sm),
              _MiniControl(icon: Design.icons.speaker),
              SizedBox(width: Design.spacing.sm),
              _MiniControl(icon: Design.icons.note),
              const Spacer(),
              Text(
                '00:25:45:00',
                style: context.typo.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: TabBar(
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: colors.card.withValues(alpha: 0),
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: context.typo.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
        ),
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return TabBarView(
      children: [
        _buildSummaryTab(context),
        _buildTranscriptTab(context),
        _buildNoteTab(context),
        _buildAssetsTab(context),
      ],
    );
  }

  Widget _buildSummaryTab(BuildContext context) {
    final summary = _summaryBlocks();

    return ListView(
      children: [
        Container(
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: context.typo.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Design.spacing.md),
              Text(
                'Attendees aligned on goals, surfaced a few delivery blockers, and assigned follow-up owners for the next sprint checkpoint.',
                style: context.typo.bodyMedium.copyWith(height: 1.45),
              ),
              SizedBox(height: Design.spacing.md),
              Wrap(
                spacing: Design.spacing.sm,
                runSpacing: Design.spacing.sm,
                children: const [
                  _MiniResultChip(label: '4 speakers'),
                  _MiniResultChip(label: '54 min'),
                  _MiniResultChip(label: '2 blockers'),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.md),
        ...summary.asMap().entries.map((entry) {
          final block = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == summary.length - 1 ? 0 : Design.spacing.md,
            ),
            child: _SectionCard(
              title: block.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: block.lines
                    .map(
                      (line) => Padding(
                        padding: EdgeInsets.only(bottom: Design.spacing.sm),
                        child: Text(line, style: context.typo.bodyMedium),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTranscriptTab(BuildContext context) {
    return Obx(() {
      final visibleMessages = controller.messages
          .where((message) => message.id != 'welcome')
          .toList();

      if (visibleMessages.isEmpty) {
        return _EmptyStateCard(
          icon: Design.icons.note,
          title: 'No transcript yet',
          subtitle: 'Start recording or ask a question to generate content.',
        );
      }

      return ListView.separated(
        controller: controller.scrollController,
        itemCount: visibleMessages.length,
        separatorBuilder: (_, index) => SizedBox(height: Design.spacing.md),
        itemBuilder: (context, index) {
          final message = visibleMessages[index];
          return _TranscriptCard(
            isUser: message.isUser,
            label: message.isUser ? 'You' : 'AtomicOS',
            content: message.content,
            status: message.isProcessing
                ? 'Processing'
                : message.isFailed
                ? 'Needs retry'
                : 'Saved',
          );
        },
      );
    });
  }

  Widget _buildNoteTab(BuildContext context) {
    final colors = context.colors;

    return ListView(
      children: [
        _SectionCard(
          title: 'Today',
          child: Text(
            controller.textController.text.isEmpty
                ? 'Today I went over the project timeline and flagged a few open questions for the upcoming task to keep us on track.'
                : controller.textController.text,
            style: context.typo.bodyMedium,
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Container(
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Context cards',
                style: context.typo.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Design.spacing.md),
              Row(
                children: const [
                  Expanded(
                    child: _ContextPreviewCard(
                      title: 'Source',
                      subtitle: 'Slack huddle',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ContextPreviewCard(
                      title: 'Participants',
                      subtitle: '4 speakers',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Container(
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ask about this Atom',
                  style: context.typo.labelLarge,
                ),
              ),
              Icon(Design.icons.sparkles, color: colors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsTab(BuildContext context) {
    return Obx(() {
      final assets = controller.messages
          .expand((message) => message.assets)
          .toList(growable: false);

      if (assets.isEmpty) {
        return ListView(
          children: [
            _EmptyStateCard(
              icon: Design.icons.emptyBox,
              title: 'No assets yet',
              subtitle: 'Attachments and imported files will appear here.',
            ),
            SizedBox(height: Design.spacing.md),
            Container(
              padding: EdgeInsets.all(Design.spacing.lg),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Design.icons.upload,
                      color: context.colors.primary,
                    ),
                  ),
                  SizedBox(width: Design.spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add more files',
                          style: context.typo.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: Design.spacing.xs),
                        Text(
                          'Upload and import previews will surface here next.',
                          style: context.typo.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return ListView.separated(
        itemCount: assets.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: Design.spacing.md),
        itemBuilder: (context, index) {
          if (index == assets.length) {
            return Container(
              padding: EdgeInsets.all(Design.spacing.lg),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Icon(Design.icons.upload, color: context.colors.primary),
                  SizedBox(width: Design.spacing.md),
                  Expanded(
                    child: Text(
                      'Add more files',
                      style: context.typo.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final asset = assets[index];
          return _SectionCard(
            title: asset.name,
            child: Row(
              children: [
                Icon(Design.icons.folder, color: context.colors.primary),
                SizedBox(width: Design.spacing.sm),
                Expanded(
                  child: Text(
                    '${asset.type.toUpperCase()} • ${asset.format.toUpperCase()}',
                    style: context.typo.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildRecordingCanvas(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(Design.spacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecordingStagePicker(context),
                SizedBox(height: Design.spacing.md),
                Text(
                  'SLACK',
                  style: context.typo.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: Design.spacing.sm),
                Text(
                  'Write a Meeting Note...',
                  style: context.typo.bodyLarge.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: Design.spacing.md),
                Row(
                  children: [
                    Icon(
                      Design.icons.attachment,
                      size: Design.spacing.iconSmall,
                      color: colors.textSecondary,
                    ),
                    SizedBox(width: Design.spacing.sm),
                    Text(
                      'Attachments',
                      style: context.typo.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Design.spacing.xl),
                Expanded(
                  child: controller.isRecordingProcessing
                      ? _buildRecordingStatusPanel(
                          context,
                          title: 'Generating outputs',
                          subtitle:
                              'Transcript segments, summary blocks, and tasks are being prepared.',
                          icon: Design.icons.sparkles,
                        )
                      : controller.isRecordingComplete
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRecordingStatusPanel(
                              context,
                              title: 'Outputs ready',
                              subtitle:
                                  'You can now review summary, transcript, note, and asset previews.',
                              icon: Design.icons.success,
                            ),
                            SizedBox(height: Design.spacing.md),
                            const _ContextPreviewCard(
                              title: 'Summary',
                              subtitle: '4 blocks generated',
                            ),
                            SizedBox(height: Design.spacing.sm),
                            const _ContextPreviewCard(
                              title: 'Tasks',
                              subtitle: '5 action items extracted',
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Text(
                            controller.textController.text.isEmpty
                                ? 'Today I went over the project timeline and flagged a few open questions to keep us on track. Today I went over the project timeline and flagged a few open questions to keep us on track.'
                                : controller.textController.text,
                            style: context.typo.bodyMedium,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Design.spacing.md),
      ],
    );
  }

  Widget _buildDetailsComposer(BuildContext context) {
    return Obx(() {
      final colors = context.colors;

      return Container(
        padding: EdgeInsets.fromLTRB(
          Design.spacing.screenPadding,
          Design.spacing.md,
          Design.spacing.screenPadding,
          Design.spacing.screenPadding,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: _showRecordingPreviewState
              ? _buildRecordingDock(context)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller.textController,
                      onChanged: controller.updateAskDraft,
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Write a Meeting Note...',
                        prefixIcon: Icon(
                          Design.icons.note,
                          color: colors.textMuted,
                        ),
                        suffixIcon: IconButton(
                          onPressed: controller.toggleListening,
                          icon: Icon(
                            Design.icons.micOutline,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Design.spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Design.spacing.md,
                              vertical: Design.spacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(
                                Design.spacing.radiusLarge,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Design.icons.attachment,
                                  size: Design.spacing.iconSmall,
                                  color: colors.textSecondary,
                                ),
                                SizedBox(width: Design.spacing.sm),
                                Text(
                                  'Attachments',
                                  style: context.typo.bodySmall.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: Design.spacing.sm),
                        SizedBox(
                          height: Design.spacing.buttonHeight,
                          child: ElevatedButton(
                            onPressed: controller.handleSend,
                            child: const Text('Ask about this Atom'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildRecordingDock(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(Design.spacing.md),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
      ),
      child: Row(
        children: [
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
                '20:18',
                style: context.typo.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(width: Design.spacing.md),
          Expanded(
            child: controller.isRecordingProcessing
                ? Text(
                    'Processing preview...',
                    style: context.typo.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : controller.isRecordingComplete
                ? Text(
                    'Ready. Open details.',
                    style: context.typo.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : VoiceLevelBars(level: controller.voiceLevel.value),
          ),
          SizedBox(width: Design.spacing.md),
          _RoundActionButton(
            icon: controller.isRecordingComplete
                ? Design.icons.rightArrow
                : controller.isRecordingPaused
                ? Design.icons.play
                : Design.icons.pause,
            background: colors.surface,
            foreground: colors.textPrimary,
            onTap: controller.cycleRecordingStage,
            label: controller.isRecordingComplete ? 'Open' : null,
          ),
          SizedBox(width: Design.spacing.sm),
          _RoundActionButton(
            icon: controller.isRecordingProcessing
                ? Design.icons.sparkles
                : Design.icons.stop,
            background: colors.primary,
            foreground: colors.background,
            onTap: controller.isRecordingComplete
                ? () => controller.setRecordingStage('recording')
                : controller.cycleRecordingStage,
            label: controller.isRecordingComplete ? 'Reset' : 'Next',
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingStagePicker(BuildContext context) {
    final colors = context.colors;
    const stages = <String, String>{
      'recording': 'Recording',
      'paused': 'Paused',
      'processing': 'Processing',
      'complete': 'Complete',
    };

    return Wrap(
      spacing: Design.spacing.sm,
      runSpacing: Design.spacing.sm,
      children: stages.entries
          .map(
            (entry) => GestureDetector(
              onTap: () => controller.setRecordingStage(entry.key),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Design.spacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: controller.recordingStage.value == entry.key
                      ? colors.primary.withValues(alpha: 0.14)
                      : colors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: controller.recordingStage.value == entry.key
                        ? colors.primary
                        : colors.border,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: context.typo.bodySmall.copyWith(
                    color: controller.recordingStage.value == entry.key
                        ? colors.primary
                        : colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRecordingStatusPanel(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return AppToneCard(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      tone: EAppToneCardTone.primary,
      padding: EdgeInsets.all(Design.spacing.lg),
    );
  }

  List<_SummaryBlock> _summaryBlocks() {
    final assistantMessages = controller.messages
        .where(
          (message) => !message.isUser && message.content.trim().isNotEmpty,
        )
        .toList();

    if (assistantMessages.isEmpty) {
      return const [
        _SummaryBlock(
          title: 'Key points',
          lines: [
            'Attendees aligned on next steps for the current sprint.',
            'Open questions were captured for follow-up.',
          ],
        ),
        _SummaryBlock(
          title: 'Action items',
          lines: [
            'Send revised API docs.',
            'Confirm launch owners.',
            'Share product showcase draft.',
          ],
        ),
      ];
    }

    return [
      _SummaryBlock(
        title: 'Summary',
        lines: assistantMessages
            .take(3)
            .map((message) => message.content.trim())
            .toList(),
      ),
      _SummaryBlock(
        title: 'Action items',
        lines: assistantMessages
            .skip(1)
            .take(3)
            .map((message) => message.content.trim())
            .toList(),
      ),
    ];
  }

  void _showRoomsBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(Design.spacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Design.spacing.radiusLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocales.ai.rooms.tr, style: context.typo.headline3),
                  AppButton(
                    type: EButtonType.text,
                    text: '+ ${AppLocales.ai.newChat.tr}',
                    onPressed: () {
                      Get.back();
                      controller.createNewRoom();
                    },
                  ),
                ],
              ),
              SizedBox(height: Design.spacing.md),
              Flexible(
                child: Obx(
                  () => ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.rooms.length,
                    itemBuilder: (context, index) {
                      final room = controller.rooms[index];
                      final isSelected =
                          controller.currentRoomId.value == room.id;

                      return AppListTile(
                        leading: Icon(
                          Design.icons.chat,
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.textSecondary,
                        ),
                        title: Text(
                          room.title,
                          style: context.typo.bodyLarge.copyWith(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          AppLocales.ai.messagesCount.trParams({
                            'count': '${room.messageCount}',
                          }),
                          style: context.typo.caption,
                        ),
                        trailing: AppButton(
                          type: EButtonType.icon,
                          icon: Design.icons.delete,
                          color: context.colors.error,
                          onPressed: () async {
                            final ok = await AppDialog.confirm(
                              context: context,
                              title: AppLocales.setting.deleteRoomTitle.tr,
                              message:
                                  AppLocales.setting.deleteRoomConfirmMsg.tr,
                              confirmLabel: AppLocales.setting.confirmDelete.tr,
                            );
                            if (ok) {
                              controller.deleteRoom(room.id);
                            }
                          },
                        ),
                        onTap: () {
                          Get.back();
                          controller.selectRoom(room);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

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
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          icon,
          size: Design.spacing.iconMedium,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  const _MiniControl({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: active ? colors.primary : colors.card,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: Design.spacing.iconSmall,
        color: active ? colors.background : colors.textSecondary,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Design.spacing.md),
          child,
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.isUser,
    required this.label,
    required this.content,
    required this.status,
  });

  final bool isUser;
  final String label;
  final String content;
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: isUser ? colors.primary.withValues(alpha: 0.14) : colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
        border: Border.all(
          color: isUser
              ? colors.primary.withValues(alpha: 0.25)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: context.typo.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUser ? colors.primary : colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                status,
                style: context.typo.caption.copyWith(color: colors.textMuted),
              ),
            ],
          ),
          SizedBox(height: Design.spacing.sm),
          Text(content, style: context.typo.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Container(
        padding: EdgeInsets.all(Design.spacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textMuted),
            SizedBox(height: Design.spacing.md),
            Text(title, style: context.typo.labelLarge),
            SizedBox(height: Design.spacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.typo.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Design.spacing.iconSmall, color: foreground),
            if (label != null) ...[
              SizedBox(width: Design.spacing.xs),
              Text(
                label!,
                style: context.typo.labelMedium.copyWith(color: foreground),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AskActionRow extends StatelessWidget {
  const _AskActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: compact ? 10 : Design.spacing.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: Design.spacing.iconSmall,
              color: context.colors.textSecondary,
            ),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: context.typo.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskSourceCard extends StatelessWidget {
  const _AskSourceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppToneCard(
      title: label,
      subtitle: 'Attach as context',
      leadingIcon: icon,
      tone: EAppToneCardTone.primary,
      onTap: onTap,
      padding: EdgeInsets.all(Design.spacing.md),
    );
  }
}

class _AskFilterChip extends StatelessWidget {
  const _AskFilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Design.spacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? colors.primary : colors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.typo.labelMedium.copyWith(
          color: selected ? colors.background : colors.textSecondary,
        ),
      ),
    );
  }
}

class _BottomMiniButton extends StatelessWidget {
  const _BottomMiniButton({
    required this.icon,
    required this.onTap,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          color: background ?? colors.card,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: foreground ?? colors.textPrimary),
      ),
    );
  }
}

class _MeetingChip extends StatelessWidget {
  const _MeetingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Design.spacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.typo.labelMedium.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

class _PreviewDocumentCard extends StatelessWidget {
  const _PreviewDocumentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 120,
      padding: EdgeInsets.all(Design.spacing.sm),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
            ),
          ),
          SizedBox(height: Design.spacing.sm),
          Text(
            'Market deck',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typo.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: Design.spacing.xs),
          Text(
            'PDF',
            style: context.typo.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniResultChip extends StatelessWidget {
  const _MiniResultChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Design.spacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.typo.bodySmall.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionBullet extends StatelessWidget {
  const _ActionBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 6),
          height: 6,
          width: 6,
          decoration: BoxDecoration(
            color: context.colors.primary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: Design.spacing.sm),
        Expanded(child: Text(text, style: context.typo.bodyMedium)),
      ],
    );
  }
}

class _ContextPreviewCard extends StatelessWidget {
  const _ContextPreviewCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppToneCard(
      title: subtitle,
      subtitle: title,
      tone: EAppToneCardTone.neutral,
      padding: EdgeInsets.all(Design.spacing.md),
    );
  }
}

class _SummaryBlock {
  const _SummaryBlock({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

class _AskActionItem {
  const _AskActionItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
