import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/modules/home/data/models/models.dart';
import 'package:rexone_mobile/services/services.dart';

import '../ai.dart';
import 'widgets/molecule_pick_card.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  // The controller is OWNED by this page instance — deliberately not a GetX
  // route registration. GetX tears popped routes down lazily, so a fast
  // exit -> re-enter reused the dying instance and its disposal killed the
  // live composer (tester report: "Ask Atomic stuck on re-entry"). An owned
  // instance cannot be touched by route cleanup.
  late final AiController controller = AiController()
    ..onInit()
    ..onReady();

  List<String> get _tabs => [
    AppLocales.atom.summary.tr,
    AppLocales.atom.transcript.tr,
    AppLocales.atom.note.tr,
    AppLocales.atom.assets.tr,
  ];
  static const _askFilters = <String>['All', 'Meetings', 'Links', 'Notes'];

  /// Tabs that actually have content — mirrors the atom-details page so a
  /// note atom's canvas shows Note + Assets only (tester: 'hide the summary
  /// and transcripts' when creating an atom from a note).
  List<int> _visibleDetailsTabIndexes() {
    final atom = controller.contextAtom.value;
    final messages = controller.messages;

    final hasSummary = atom != null
        ? atom.summaryBlocks.isNotEmpty
        : messages.any(
            (m) =>
                !m.isUser && m.id != 'welcome' && m.content.trim().isNotEmpty,
          );
    final hasTranscript = atom != null
        ? atom.transcriptSegments.isNotEmpty
        : messages.any((m) => m.id != 'welcome');

    return [if (hasSummary) 0, if (hasTranscript) 1, 2, 3];
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isAskMode) {
        return AppPage(
          backgroundColor: context.colors.background,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Pinned chat header — stays visible while the conversation
              // scrolls (tester report: it vanished at the end of long
              // threads because it lived inside the scroll view).
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Design.spacing.screenPadding,
                  Design.spacing.md,
                  Design.spacing.screenPadding,
                  0,
                ),
                child: _buildAskTopBar(context),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Design.spacing.screenPadding,
                    Design.spacing.lg,
                    Design.spacing.screenPadding,
                    0,
                  ),
                  child: SingleChildScrollView(
                    controller: controller.scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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

      // Only tabs with real content — note atoms drop Summary/Transcript
      // (mirrors the atom-details page; testers: 'hide the summary and
      // transcripts' when creating an atom from a note).
      final visibleTabs = _visibleDetailsTabIndexes();

      return DefaultTabController(
        length: visibleTabs.length,
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
                    _buildTabs(context, visibleTabs),
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
                      : _buildTabContent(context, visibleTabs),
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
          child: AppNeumoSurface(
            circle: true,
            soft: true,
            width: 28,
            height: 28,
            padding: EdgeInsets.zero,
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

    return AppNeumoSurface(
      width: double.infinity,
      radius: Design.spacing.radiusXLarge,
      padding: EdgeInsets.all(Design.spacing.lg),
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
            AppLocales.ai.meetingNoteHint.tr,
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
                    title: AppLocales.ai.processingMeeting.tr,
                    subtitle: AppLocales.ai.processingMeetingSub.tr,
                    icon: Design.icons.sparkles,
                  )
                : controller.isRecordingComplete
                ? _buildRecordingStatusPanel(
                    context,
                    title: AppLocales.ai.meetingReady.tr,
                    subtitle: AppLocales.ai.meetingReadySub.tr,
                    icon: Design.icons.success,
                  )
                : TextField(
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
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
                      filled: true,
                    fillColor: Colors.transparent,
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
              title: AppLocales.ai.recordingPausedTitle.tr,
              subtitle: AppLocales.ai.recordingPausedSub.tr,
              icon: Design.icons.pause,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAskFlow(BuildContext context) {
    if (controller.showAskResultPreview) {
      return _buildAskConversation(context);
    }

    if (controller.showAskSourceResults) {
      return _buildAskContextPicker(context);
    }

    return _buildAskLanding(context);
  }

  Widget _buildAskLanding(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Design.spacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary.withValues(alpha: 0.14), colors.neumo],
            ),
            borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _askTitleText(
                context,
                style: context.typo.headline3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Design.spacing.xs),
              Text(
                AppLocales.ai.askSubtitle.tr,
                style: context.typo.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: Design.spacing.md),
              Wrap(
                spacing: Design.spacing.sm,
                runSpacing: Design.spacing.sm,
                children: [
                  _MiniResultChip(label: AppLocales.ai.resultSummary.tr),
                  _MiniResultChip(label: AppLocales.ai.resultDecisions.tr),
                  _MiniResultChip(label: AppLocales.ai.resultTasks.tr),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.xxl),
        ..._buildAskActionItems().map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: Design.spacing.sm),
            child: _AskActionRow(
              icon: item.icon,
              label: item.label,
              subtitle: item.subtitle,
              onTap: () => controller.applyPromptSuggestion(item.label),
            ),
          ),
        ),
        SizedBox(height: Design.spacing.lg),
        Obx(() {
          final preview = controller.attachmentName.value;
          if (preview == null || preview.isEmpty) {
            return const SizedBox.shrink();
          }

          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: Design.spacing.md),
              child: _ComposerChip(
                icon: Design.icons.attachment,
                label: preview,
                onRemove: controller.clearAskAttachment,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAskContextPicker(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocales.ai.chooseContext.tr,
          style: context.typo.headline3.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.xs),
        Text(
          AppLocales.ai.chooseContextSub.tr,
          style: context.typo.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: Design.spacing.lg),
        AppGlassCard(
          padding: EdgeInsets.symmetric(
            horizontal: Design.spacing.md,
            vertical: Design.spacing.sm,
          ),
          radius: Design.spacing.radiusLarge,
          child: Row(
            children: [
              Icon(
                Design.icons.search,
                size: Design.spacing.iconSmall,
                color: colors.textMuted,
              ),
              SizedBox(width: Design.spacing.sm),
              Expanded(
                child: TextField(
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  controller: controller.searchContextController,
                  onChanged: (value) => controller.loadContextAtoms(value),
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: AppLocales.ai.searchAtomsHint.tr,
                    hintStyle: context.typo.bodySmall.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Obx(() {
          final filter = controller.contextFilter.value ?? 'All';
          return Wrap(
            spacing: Design.spacing.xs,
            runSpacing: Design.spacing.xs,
            children: _askFilters
                .map(
                  (label) => _AskFilterChip(
                    label: label,
                    selected: label == filter,
                    onTap: () => controller.setContextFilter(label),
                  ),
                )
                .toList(),
          );
        }),
        SizedBox(height: Design.spacing.lg),
        Obx(() {
          if (controller.isLoadingContext.value) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: Design.spacing.xxl),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final atoms = controller.filteredContextAtoms;
          if (atoms.isEmpty) {
            return AppGlassCard(
              padding: EdgeInsets.all(Design.spacing.xl),
              radius: Design.spacing.radiusXLarge,
              child: Column(
                children: [
                  Icon(Design.icons.atomAdd, size: 36, color: colors.textMuted),
                  SizedBox(height: Design.spacing.md),
                  Text(
                    AppLocales.ai.noAtomsHere.tr,
                    style: context.typo.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: Design.spacing.xs),
                  Text(
                    AppLocales.ai.noAtomsHereSub.tr,
                    textAlign: TextAlign.center,
                    style: context.typo.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: atoms
                .map(
                  (atom) => Padding(
                    padding: EdgeInsets.only(bottom: Design.spacing.sm),
                    child: _ContextAtomCard(
                      atom: atom,
                      onTap: () => controller.attachContextAtom(atom),
                    ),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildAskConversation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final msgs = controller.messages;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...msgs.map(
                (message) => Padding(
                  padding: EdgeInsets.only(bottom: Design.spacing.md),
                  child: _ChatBubble(
                    message: message,
                    speaking: controller.activeTtsMessageId.value == message.id,
                    loadingTts:
                        controller.isTtsLoading.value &&
                        controller.activeTtsMessageId.value == message.id,
                    onSpeak: () => controller.speakMessage(message),
                    onCopy: () => _copyMessage(message.content),
                    onRetry: () => controller.retryLastTurn(),
                  ),
                ),
              ),
              if (controller.isProcessing.value)
                Padding(
                  padding: EdgeInsets.only(bottom: Design.spacing.md),
                  child: const _ThinkingBubble(),
                ),
            ],
          );
        }),
        SizedBox(height: Design.spacing.sm),
        _buildAskActionChips(context),
        Obx(() {
          if (controller.askActionData.value == null &&
              !controller.isRunningAskAction.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(top: Design.spacing.lg),
            child: _buildActionResultCard(context),
          );
        }),
        SizedBox(height: Design.spacing.lg),
      ],
    );
  }

  Widget _buildAskActionChips(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final busy = controller.isRunningAskAction.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocales.ai.workWithAnswer.tr,
            style: context.typo.labelMedium.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Design.spacing.sm),
          Wrap(
            spacing: Design.spacing.sm,
            runSpacing: Design.spacing.sm,
            children: _buildAskActionItems()
                .map(
                  (item) => _AskActionChip(
                    icon: item.icon,
                    label: item.label,
                    busy: busy,
                    onTap: busy
                        ? null
                        : () => controller.runAskAction(item.label),
                  ),
                )
                .toList(),
          ),
        ],
      );
    });
  }

  Widget _buildActionResultCard(BuildContext context) {
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
                Icon(
                  Design.icons.sparkles,
                  size: Design.spacing.iconSmall,
                  color: colors.primary,
                ),
                SizedBox(width: Design.spacing.xs),
                Expanded(
                  child: Text(
                    controller.askActionTitle.value,
                    style: context.typo.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (controller.isRunningAskAction.value)
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () =>
                        _copyMessage(controller.askActionLines.join('\n')),
                    child: Icon(
                      Design.icons.clipboard,
                      size: Design.spacing.iconSmall,
                      color: colors.textMuted,
                    ),
                  ),
              ],
            ),
            SizedBox(height: Design.spacing.md),
            if (controller.isRunningAskAction.value)
              Padding(
                padding: EdgeInsets.symmetric(vertical: Design.spacing.xl),
                child: const Center(child: CircularProgressIndicator()),
              )
            else
              _buildActionResultContent(context),
          ],
        ),
      ),
    );
  }

  void _copyMessage(String content) {
    final text = content.trim();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.success(AppLocales.atom.copiedToClipboard.tr);
  }

  /// Composer attach flow: a soft-UI sheet over the chat. The old "+" swapped
  /// the whole conversation out for a cramped row on the landing screen —
  /// the sheet keeps the chat behind, offers Photo / Files / context-atom as
  /// full rows, and hosts the atom picker as a second panel.
  void _showAttachSheet() {
    Get.bottomSheet<void>(
      _AskAttachSheet(controller: controller),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

    if (lines.isEmpty) {
      return Text(
        AppLocales.ai.runActionHint.tr,
        style: context.typo.bodyMedium.copyWith(height: 1.45),
      );
    }

    return _ChatMarkdown(data: lines.take(3).join('\n\n'));
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
          Text(summary, style: context.typo.bodyMedium.copyWith(height: 1.45)),
        if (keyPoints is List && keyPoints.isNotEmpty) ...[
          SizedBox(height: Design.spacing.md),
          _reportSection(context, AppLocales.ai.keyPoints.tr, keyPoints),
        ],
        if (actionItems is List && actionItems.isNotEmpty) ...[
          SizedBox(height: Design.spacing.md),
          _reportSection(context, AppLocales.ai.actionItems.tr, actionItems),
        ],
        if (risks is List && risks.isNotEmpty) ...[
          SizedBox(height: Design.spacing.md),
          _reportSection(context, AppLocales.ai.risks.tr, risks),
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
          style: context.typo.labelMedium.copyWith(fontWeight: FontWeight.w700),
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

  /// The ask title: molecule conversations announce their molecule
  /// ("Ask General"); everything else stays the generic "Ask AtomicOS".
  Widget _askTitleText(
    BuildContext context, {
    required TextStyle style,
    TextAlign? textAlign,
  }) {
    return Obx(() {
      final molecule = controller.currentMoleculeName.value;
      return Text(
        (molecule == null || molecule.isEmpty)
            ? AppLocales.ai.askTitle.tr
            : AppLocales.ai.askNamed.trParams({'name': molecule}),
        textAlign: textAlign,
        style: style,
      );
    });
  }

  Widget _buildAskTopBar(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Design.icons.backArrow, onTap: Get.back),
        Expanded(
          child: _askTitleText(
            context,
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

    return AppNeumoSurface(
      radius: Design.spacing.radiusXLarge,
      padding: EdgeInsets.fromLTRB(
        Design.spacing.screenPadding,
        Design.spacing.sm,
        Design.spacing.screenPadding,
        Design.spacing.screenPadding,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final atom = controller.contextAtom.value;
              final molecule = controller.contextMolecule.value;
              final attachment = controller.attachmentName.value;
              if (molecule == null &&
                  atom == null &&
                  (attachment == null || attachment.isEmpty)) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: EdgeInsets.only(bottom: Design.spacing.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: Design.spacing.sm,
                    runSpacing: Design.spacing.sm,
                    children: [
                      if (molecule != null)
                        _ComposerChip(
                          icon: Design.icons.molecule,
                          label: molecule.name,
                          onRemove: controller.clearContextMolecule,
                        ),
                      if (atom != null)
                        _ComposerChip(
                          icon: Design.icons.atomAdd,
                          label: atom.title,
                          onRemove: controller.clearContextAtom,
                        ),
                      if (attachment != null && attachment.isNotEmpty)
                        _ComposerChip(
                          icon: Design.icons.attachment,
                          label: attachment,
                          onRemove: controller.clearAskAttachment,
                        ),
                    ],
                  ),
                ),
              );
            }),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ComposerIconButton(
                  icon: Design.icons.add,
                  onTap: () => _showAttachSheet(),
                ),
                SizedBox(width: Design.spacing.sm),
                Expanded(
                  // The field is a well pressed into the raised composer bar.
                  child: AppNeumoSurface(
                    depth: ENeumoDepth.inset,
                    radius: Design.spacing.radiusXLarge,
                    padding: EdgeInsets.symmetric(
                      horizontal: Design.spacing.md,
                      vertical: 10,
                    ),
                    child: TextField(
                      controller: controller.textController,
                      onChanged: controller.updateAskDraft,
                      // Tapping anywhere outside drops the keyboard — testers
                      // could not dismiss it before sending.
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: AppLocales.ai.composerHint.tr,
                        hintStyle: context.typo.bodyMedium.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Design.spacing.sm),
                Obx(() {
                  final busy = controller.isProcessing.value;
                  return GestureDetector(
                    onTap: busy
                        ? controller.stopProcessing
                        : controller.handleSend,
                    child: busy
                        ? AppNeumoSurface(
                            circle: true,
                            soft: true,
                            width: 40,
                            height: 40,
                            padding: EdgeInsets.zero,
                            child: Icon(
                              Design.icons.stop,
                              size: 18,
                              color: colors.textPrimary,
                            ),
                          )
                        : Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Design.icons.send,
                              size: 18,
                              color: colors.onPrimary,
                            ),
                          ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_AskActionItem> _buildAskActionItems() {
    return [
      _AskActionItem(
        icon: Design.icons.bolt,
        label: AppLocales.ai.resultSummary.tr,
        subtitle: AppLocales.ai.actionSummarySub.tr,
      ),
      _AskActionItem(
        icon: Design.icons.route,
        label: AppLocales.ai.resultDecisions.tr,
        subtitle: AppLocales.ai.actionDecisionsSub.tr,
      ),
      _AskActionItem(
        icon: Design.icons.sparkles,
        label: AppLocales.ai.actionFusion.tr,
        subtitle: AppLocales.ai.actionFusionSub.tr,
      ),
      _AskActionItem(
        icon: Design.icons.task,
        label: AppLocales.ai.actionTasks.tr,
        subtitle: AppLocales.ai.actionTasksSub.tr,
      ),
      _AskActionItem(
        icon: Design.icons.report,
        label: AppLocales.ai.actionReport.tr,
        subtitle: AppLocales.ai.actionReportSub.tr,
      ),
    ];
  }

  Widget _buildDetailsTopBar(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Design.icons.backArrow, onTap: Get.back),
        Expanded(
          child: Text(
            AppLocales.ai.detailsTab.tr,
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

    return AppNeumoSurface(
      radius: Design.spacing.radiusLarge,
      padding: EdgeInsets.all(Design.spacing.lg),
      child: Column(
        children: [
          // The track is a groove cut into the card; the bar rides inside it,
          // so the indicator itself stays transparent.
          AppNeumoSurface(
            depth: ENeumoDepth.inset,
            radius: 3,
            soft: true,
            padding: EdgeInsets.zero,
            child: LinearProgressIndicator(
              value: hasMessages ? 0.32 : 0.0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
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

  Widget _buildTabs(BuildContext context, List<int> visibleTabs) {
    final colors = context.colors;

    // Track is recessed so the selected tab indicator reads as sitting on top.
    return AppNeumoSurface(
      depth: ENeumoDepth.inset,
      radius: 999,
      padding: EdgeInsets.all(4),
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
        tabs: visibleTabs.map((index) => Tab(text: _tabs[index])).toList(),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<int> visibleTabs) {
    return TabBarView(
      children: visibleTabs.map((index) {
        switch (index) {
          case 0:
            return _buildSummaryTab(context);
          case 1:
            return _buildTranscriptTab(context);
          case 2:
            return _buildNoteTab(context);
          default:
            return _buildAssetsTab(context);
        }
      }).toList(),
    );
  }

  Widget _buildSummaryTab(BuildContext context) {
    final summary = _summaryBlocks();

    if (summary.isEmpty) {
      return ListView(
        children: [
          _EmptyStateCard(
            icon: Design.icons.sparkles,
            title: AppLocales.atom.noSummary.tr,
            subtitle: AppLocales.ai.noTranscriptSub.tr,
          ),
        ],
      );
    }

    return ListView(
      children: [
        ...summary.asMap().entries.map((entry) {
          final block = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == summary.length - 1 ? 0 : Design.spacing.md,
            ),
            child: AppToneCard(
              title: block.title,
              leadingIcon: entry.key == 0
                  ? Design.icons.sparkles
                  : Design.icons.task,
              tone: entry.key == 0
                  ? EAppToneCardTone.primary
                  : EAppToneCardTone.info,
              footer: Column(
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
      // A pinned atom's own transcript wins over the chat log.
      final atomSegments = controller.contextAtom.value?.transcriptSegments;
      if (atomSegments != null && atomSegments.isNotEmpty) {
        final lines = <String>[];
        for (final raw in atomSegments) {
          final map = raw is Map
              ? Map<String, dynamic>.from(raw)
              : <String, dynamic>{};
          final text = (map['text'] ?? map['content'] ?? '').toString().trim();
          if (text.isNotEmpty) lines.add(text);
        }
        if (lines.isNotEmpty) {
          return ListView.separated(
            itemCount: lines.length,
            separatorBuilder: (_, index) => SizedBox(height: Design.spacing.md),
            itemBuilder: (context, index) => _TranscriptCard(
              isUser: false,
              label: 'AtomicOS',
              content: lines[index],
              status: 'Saved',
            ),
          );
        }
      }

      final visibleMessages = controller.messages
          .where((message) => message.id != 'welcome')
          .toList();

      if (visibleMessages.isEmpty) {
        return _EmptyStateCard(
          icon: Design.icons.note,
          title: AppLocales.ai.noTranscript.tr,
          subtitle: AppLocales.ai.noTranscriptSub.tr,
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
                ? AppLocales.ai.needsRetry.tr
                : 'Saved',
          );
        },
      );
    });
  }

  Widget _buildNoteTab(BuildContext context) {
    return ListView(
      children: [
        AppToneCard(
          title: AppLocales.ai.today.tr,
          leadingIcon: Design.icons.note,
          tone: EAppToneCardTone.primary,
          footer: Text(_canvasNoteText(), style: context.typo.bodyMedium),
        ),
        SizedBox(height: Design.spacing.md),
        // Real context only — this card used to show demo values ('Slack
        // huddle' / '4 speakers'); it hides entirely without a pinned atom.
        Obx(() {
          final atom = controller.contextAtom.value;
          if (atom == null) return const SizedBox.shrink();

          return AppCard(
            padding: EdgeInsets.all(Design.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocales.ai.contextCards.tr,
                  style: context.typo.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Design.spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _ContextPreviewCard(
                        title: AppLocales.ai.source.tr,
                        subtitle: atom.source,
                      ),
                    ),
                    if (atom.participantsCount != null) ...[
                      SizedBox(width: 12),
                      Expanded(
                        child: _ContextPreviewCard(
                          title: AppLocales.ai.participants.tr,
                          subtitle: '${atom.participantsCount}',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
        SizedBox(height: Design.spacing.md),
        AppToneCard(
          title: AppLocales.ai.askAboutThisAtom.tr,
          subtitle: AppLocales.ai.askAboutThisAtomSub.tr,
          leadingIcon: Design.icons.sparkles,
          tone: EAppToneCardTone.primary,
        ),
      ],
    );
  }

  /// Real note content for the canvas Note tab: the context atom's note when
  /// present, otherwise the ask draft (no demo filler).
  String _canvasNoteText() {
    final atomNote = controller.contextAtom.value?.note?.trim() ?? '';
    if (atomNote.isNotEmpty) return atomNote;
    final draft = controller.textController.text.trim();
    if (draft.isNotEmpty) return draft;
    return AppLocales.atom.nothingHere.tr;
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
              title: AppLocales.ai.noAssets.tr,
              subtitle: AppLocales.ai.noAssetsSub.tr,
            ),
            SizedBox(height: Design.spacing.md),
            AppToneCard(
              title: AppLocales.ai.addMoreFiles.tr,
              subtitle: AppLocales.ai.addMoreFilesSub1.tr,
              leadingIcon: Design.icons.upload,
              tone: EAppToneCardTone.primary,
            ),
          ],
        );
      }

      return ListView.separated(
        itemCount: assets.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: Design.spacing.md),
        itemBuilder: (context, index) {
          if (index == assets.length) {
            return AppToneCard(
              title: AppLocales.ai.addMoreFiles.tr,
              subtitle: AppLocales.ai.addMoreFilesSub2.tr,
              leadingIcon: Design.icons.upload,
              tone: EAppToneCardTone.primary,
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
                    '${asset.type.toUpperCase()} • ${asset.format?.toUpperCase() ?? ''}',
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
          child: AppNeumoSurface(
            radius: Design.spacing.radiusLarge,
            padding: EdgeInsets.all(Design.spacing.lg),
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
                  AppLocales.ai.meetingNoteHint.tr,
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
                      AppLocales.ai.attachments.tr,
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
                          title: AppLocales.ai.generatingOutputs.tr,
                          subtitle: AppLocales.ai.processingPanelSub.tr,
                          icon: Design.icons.sparkles,
                        )
                      : controller.isRecordingComplete
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRecordingStatusPanel(
                              context,
                              title: AppLocales.ai.outputsReady.tr,
                              subtitle: AppLocales.ai.outputsReadySub.tr,
                              icon: Design.icons.success,
                            ),
                            SizedBox(height: Design.spacing.md),
                            _ContextPreviewCard(
                              title: AppLocales.ai.resultSummary.tr,
                              subtitle: '4 blocks generated',
                            ),
                            SizedBox(height: Design.spacing.sm),
                            _ContextPreviewCard(
                              title: AppLocales.ai.resultTasks.tr,
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
          color: colors.neumo,
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
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      controller: controller.textController,
                      onChanged: controller.updateAskDraft,
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: AppLocales.ai.meetingNoteHint.tr,
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
                                Flexible(
                                  child: Text(
                                    AppLocales.ai.attachments.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.typo.bodySmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: Design.spacing.sm),
                        Flexible(
                          child: SizedBox(
                            height: Design.spacing.buttonHeight,
                            child: ElevatedButton(
                              // The app theme styles buttons full-width
                              // (minWidth: infinity), which cannot lay out
                              // inside a Row — hug the content and shrink
                              // gracefully instead.
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.symmetric(
                                  horizontal: Design.spacing.md,
                                ),
                              ),
                              onPressed: controller.handleSend,
                              child: Text(
                                AppLocales.ai.askAboutThisAtom.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                    AppLocales.ai.processingPreview.tr,
                    style: context.typo.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : controller.isRecordingComplete
                ? Text(
                    AppLocales.ai.readyOpenDetails.tr,
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
    // A pinned atom shows its real summary blocks first.
    final atom = controller.contextAtom.value;
    if (atom != null && atom.summaryBlocks.isNotEmpty) {
      final blocks = <_SummaryBlock>[];
      for (final raw in atom.summaryBlocks) {
        final map = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        final text = (map['text'] ?? map['content'] ?? '').toString().trim();
        if (text.isEmpty) continue;
        blocks.add(
          _SummaryBlock(title: AppLocales.ai.resultSummary.tr, lines: [text]),
        );
      }
      if (blocks.isNotEmpty) return blocks;
    }

    final assistantMessages = controller.messages
        .where(
          (message) => !message.isUser && message.content.trim().isNotEmpty,
        )
        .toList();

    if (assistantMessages.isEmpty) {
      return const [];
    }

    return [
      _SummaryBlock(
        title: AppLocales.ai.resultSummary.tr,
        lines: assistantMessages
            .take(3)
            .map((message) => message.content.trim())
            .toList(),
      ),
      _SummaryBlock(
        title: AppLocales.ai.actionItems.tr,
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
      AppNeumoSurface(
        radius: Design.spacing.radiusLarge,
        padding: EdgeInsets.all(Design.spacing.lg),
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
                          (room.categoryId ?? '').isEmpty
                              ? Design.icons.chat
                              : Design.icons.molecule,
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
      child: AppNeumoSurface(
        circle: true,
        soft: true,
        width: 36,
        height: 36,
        padding: EdgeInsets.zero,
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
          _ChatMarkdown(data: content),
        ],
      ),
    );
  }
}

/// Renders a chat message body as markdown, sized for a bubble or card.
class _ChatMarkdown extends StatelessWidget {
  const _ChatMarkdown({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.typo.bodyMedium.copyWith(
      color: colors.textPrimary,
      height: 1.45,
    );

    return MarkdownBody(
      data: data,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: base,
        strong: base.copyWith(fontWeight: FontWeight.w700),
        em: base.copyWith(fontStyle: FontStyle.italic),
        h1: context.typo.headline3.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        h2: context.typo.headline4.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        h3: context.typo.labelLarge.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        listBullet: base,
        blockquote: base.copyWith(color: colors.textSecondary),
        blockquoteDecoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          border: Border(left: BorderSide(color: colors.primary, width: 3)),
        ),
        code: context.typo.bodySmall.copyWith(
          color: colors.primary,
          backgroundColor: colors.primary.withValues(alpha: 0.08),
        ),
        codeblockDecoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
          border: Border.all(color: colors.border),
        ),
        codeblockPadding: EdgeInsets.all(Design.spacing.sm),
        tableBorder: TableBorder.all(color: colors.border),
        a: base.copyWith(
          color: colors.primary,
          decoration: TextDecoration.underline,
        ),
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
      child: AppNeumoSurface(
        radius: Design.spacing.radiusLarge,
        padding: EdgeInsets.all(Design.spacing.xl),
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
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppNeumoSurface(
        width: double.infinity,
        radius: Design.spacing.radiusLarge,
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: Design.spacing.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: Design.spacing.iconSmall,
              color: context.colors.primary,
            ),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: context.typo.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.caption.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Icon(
              Design.icons.rightArrow,
              size: Design.spacing.iconSmall,
              color: context.colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AskFilterChip extends StatelessWidget {
  const _AskFilterChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      // An active filter looks pressed in; the rest stay lifted.
      child: AppNeumoSurface(
        depth: selected ? ENeumoDepth.inset : ENeumoDepth.raised,
        radius: 999,
        soft: true,
        color: selected ? colors.primary : colors.neumo,
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.sm,
          vertical: 6,
        ),
        child: Text(
          label,
          style: context.typo.labelMedium.copyWith(
            color: selected ? colors.onPrimary : colors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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

class _MiniResultChip extends StatelessWidget {
  const _MiniResultChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppNeumoSurface(
      soft: true,
      radius: 999,
      padding: EdgeInsets.symmetric(horizontal: Design.spacing.sm, vertical: 6),
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
  const _AskActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;
}

/// Small soft-UI avatar marking assistant messages.
class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppNeumoSurface(
      circle: true,
      soft: true,
      width: 28,
      height: 28,
      padding: EdgeInsets.zero,
      child: Icon(Design.icons.sparkles, size: 14, color: colors.primary),
    );
  }
}

/// Compact icon action shown under a bubble (speak / copy).
class _BubbleAction extends StatelessWidget {
  const _BubbleAction({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/// Tappable "Retry" pill under a failed assistant message.
class _RetryChip extends StatelessWidget {
  const _RetryChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Design.icons.refresh, size: 13, color: colors.error),
            const SizedBox(width: 4),
            Text(
              AppLocales.ai.retry.tr,
              style: context.typo.caption.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.speaking,
    required this.loadingTts,
    required this.onSpeak,
    required this.onCopy,
    required this.onRetry,
  });

  final AiMessageModel message;
  final bool speaking;
  final bool loadingTts;
  final VoidCallback onSpeak;
  final VoidCallback onCopy;
  final VoidCallback onRetry;

  static String _time(BuildContext context, String createdAt) {
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return '';
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(parsed.toLocal()),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isUser = message.isUser;
    final pending = message.isProcessing;
    final failed = message.isFailed;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.80 : 0.74),
      ),
      padding: EdgeInsets.all(Design.spacing.md),
      decoration: BoxDecoration(
        color: isUser ? colors.primary.withValues(alpha: 0.14) : colors.neumo,
        boxShadow: isUser ? null : colors.neumoShadow,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Design.spacing.radiusLarge),
          topRight: Radius.circular(Design.spacing.radiusLarge),
          bottomLeft: Radius.circular(isUser ? Design.spacing.radiusLarge : 6),
          bottomRight: Radius.circular(isUser ? 6 : Design.spacing.radiusLarge),
        ),
      ),
      child: pending && message.content.trim().isEmpty
          ? const AppLoading(type: LoadingType.dots, size: LoadingSize.small)
          : _ChatMarkdown(data: message.content),
    );

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _time(context, message.createdAt),
          style: context.typo.caption.copyWith(color: colors.textMuted),
        ),
        if (failed) ...[
          SizedBox(width: Design.spacing.sm),
          _RetryChip(onTap: onRetry),
        ] else if (!isUser && !pending) ...[
          SizedBox(width: Design.spacing.sm),
          _BubbleAction(
            icon: loadingTts ? Design.icons.clock : Design.icons.speaker,
            color: speaking ? colors.primary : colors.textMuted,
            onTap: loadingTts ? null : onSpeak,
          ),
          SizedBox(width: Design.spacing.sm),
          _BubbleAction(
            icon: Design.icons.clipboard,
            color: colors.textMuted,
            onTap: onCopy,
          ),
        ],
      ],
    );

    final body = Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [bubble, const SizedBox(height: 6), meta],
    );

    if (isUser) return body;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AssistantAvatar(),
        SizedBox(width: Design.spacing.sm),
        Flexible(child: body),
      ],
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AssistantAvatar(),
        SizedBox(width: Design.spacing.sm),
        AppNeumoSurface(
          soft: true,
          radius: Design.spacing.radiusLarge,
          padding: EdgeInsets.symmetric(
            horizontal: Design.spacing.md,
            vertical: Design.spacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoading(type: LoadingType.dots, size: LoadingSize.small),
              SizedBox(width: Design.spacing.sm),
              Text(
                AppLocales.ai.thinking.tr,
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

class _AskActionChip extends StatelessWidget {
  const _AskActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AppNeumoSurface(
        soft: true,
        radius: 999,
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: Design.spacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: busy ? colors.textMuted : colors.primary,
            ),
            SizedBox(width: 6),
            // Chips sit in a Wrap — a long label must ellipsize instead of
            // overflowing the row by a few pixels.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typo.labelMedium.copyWith(
                  color: busy ? colors.textMuted : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for the composer attach flow: Photo / Files / context-atom
/// as full rows over the chat, with the atom picker as a second panel.
class _AskAttachSheet extends StatefulWidget {
  const _AskAttachSheet({required this.controller});

  final AiController controller;

  @override
  State<_AskAttachSheet> createState() => _AskAttachSheetState();
}

class _AskAttachSheetState extends State<_AskAttachSheet> {
  static const _filters = <String>['All', 'Meetings', 'Links', 'Notes'];

  bool _showContext = false;
  bool _showMolecules = false;

  AiController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: _showMolecules
          ? _buildMoleculesPanel(context)
          : _showContext
          ? _buildContextPanel(context)
          : _buildOptionsPanel(context),
    );
  }

  Widget _buildOptionsPanel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocales.ai.attachSheetTitle.tr,
          style: context.typo.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.md),
        _AttachOption(
          icon: Design.icons.gallery,
          title: AppLocales.ai.askSourcePhoto.tr,
          subtitle: AppLocales.ai.sourcePhotoSub.tr,
          onTap: () {
            // GetX quirk: Get.back() closes an OPEN SNACKBAR instead of the
            // route (get 4.7.3 back() returns early while a snackbar shows).
            // Clear any lingering snackbar so the sheet always dismisses.
            Get.closeAllSnackbars();
            Get.back();
            controller.selectAskAttachment('Photo');
          },
        ),
        SizedBox(height: Design.spacing.sm),
        _AttachOption(
          icon: Design.icons.folder,
          title: AppLocales.ai.askSourceFiles.tr,
          subtitle: AppLocales.ai.sourceFilesSub.tr,
          onTap: () {
            Get.closeAllSnackbars();
            Get.back();
            controller.selectAskAttachment('Files');
          },
        ),
        SizedBox(height: Design.spacing.sm),
        _AttachOption(
          icon: Design.icons.atomAdd,
          title: AppLocales.ai.askSourceAtom.tr,
          subtitle: AppLocales.ai.sourceAtomSub.tr,
          onTap: () {
            setState(() => _showContext = true);
            // Fresh canvas every time: drop any stale search so the picker
            // shows the current selection alongside the full list.
            controller.searchContextController.clear();
            controller.loadContextAtoms();
          },
        ),
        SizedBox(height: Design.spacing.sm),
        _AttachOption(
          icon: Design.icons.molecule,
          title: AppLocales.ai.askSourceMolecule.tr,
          subtitle: AppLocales.ai.sourceMoleculeSub.tr,
          onTap: () {
            setState(() {
              _showContext = false;
              _showMolecules = true;
            });
            // The user's own molecules; silent refresh keeps the last state.
            Get.find<CategoryService>().refresh();
          },
        ),
      ],
    );
  }

  Widget _buildContextPanel(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showContext = false),
              child: Icon(
                Design.icons.backArrow,
                size: Design.spacing.iconSmall,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Text(
              AppLocales.ai.chooseContext.tr,
              style: context.typo.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: Design.spacing.xs),
        Text(
          AppLocales.ai.chooseContextSub.tr,
          style: context.typo.caption.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: Design.spacing.md),
        AppNeumoSurface(
          depth: ENeumoDepth.inset,
          radius: Design.spacing.radiusXLarge,
          padding: EdgeInsets.symmetric(
            horizontal: Design.spacing.md,
            vertical: 10,
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
                child: TextField(
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  controller: controller.searchContextController,
                  onChanged: (value) => controller.loadContextAtoms(value),
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: AppLocales.ai.searchAtomsHint.tr,
                    hintStyle: context.typo.bodySmall.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Obx(() {
          final filter = controller.contextFilter.value ?? 'All';
          return Wrap(
            spacing: Design.spacing.xs,
            runSpacing: Design.spacing.xs,
            children: _filters
                .map(
                  (label) => _AskFilterChip(
                    label: label,
                    selected: label == filter,
                    onTap: () => controller.setContextFilter(label),
                  ),
                )
                .toList(),
          );
        }),
        SizedBox(height: Design.spacing.md),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.40,
          ),
          child: Obx(() {
            if (controller.isLoadingContext.value) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: Design.spacing.xxl),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final atoms = controller.filteredContextAtoms;
            if (atoms.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: Design.spacing.xl),
                child: Column(
                  children: [
                    Icon(
                      Design.icons.atomAdd,
                      size: 32,
                      color: colors.textMuted,
                    ),
                    SizedBox(height: Design.spacing.sm),
                    Text(
                      AppLocales.ai.noAtomsHere.tr,
                      style: context.typo.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: atoms.length,
              separatorBuilder: (_, _) => SizedBox(height: Design.spacing.sm),
              itemBuilder: (context, index) => _ContextAtomCard(
                atom: atoms[index],
                selected: controller.contextAtom.value?.id == atoms[index].id,
                onTap: () {
                  // Close the sheet BEFORE attaching: attachContextAtom fires a
                  // snackbar, and Get.back() while a snackbar is open closes the
                  // SNACKBAR and returns — the sheet used to stay hanging open.
                  Get.closeAllSnackbars();
                  Get.back();
                  controller.attachContextAtom(atoms[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  /// The user's molecules — picking one grounds the conversation in the WHOLE
  /// molecule: the AI receives every atom inside it.
  Widget _buildMoleculesPanel(BuildContext context) {
    final colors = context.colors;
    final categoryService = Get.find<CategoryService>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showMolecules = false),
              child: Icon(
                Design.icons.backArrow,
                size: Design.spacing.iconSmall,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            Text(
              AppLocales.ai.chooseMolecule.tr,
              style: context.typo.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: Design.spacing.xs),
        Text(
          AppLocales.ai.chooseMoleculeSub.tr,
          style: context.typo.caption.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: Design.spacing.md),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.40,
          ),
          child: Obx(() {
            final molecules = categoryService.categories;
            if (molecules.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: Design.spacing.xl),
                child: Column(
                  children: [
                    Icon(
                      Design.icons.molecule,
                      size: 32,
                      color: colors.textMuted,
                    ),
                    SizedBox(height: Design.spacing.sm),
                    Text(
                      AppLocales.ai.noMoleculesHere.tr,
                      textAlign: TextAlign.center,
                      style: context.typo.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: molecules.length,
              separatorBuilder: (_, _) => SizedBox(height: Design.spacing.sm),
              itemBuilder: (context, index) => MoleculePickCard(
                molecule: molecules[index],
                selected:
                    controller.contextMolecule.value?.id == molecules[index].id,
                onTap: () {
                  // Close the sheet BEFORE attaching (GetX trap: an open
                  // snackbar makes Get.back() close the snackbar instead).
                  Get.closeAllSnackbars();
                  Get.back();
                  controller.attachContextMolecule(molecules[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Shared soft-UI chrome for the attach sheets (handle, rounded top, rising
/// with the keyboard).
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppNeumoSurface(
      margin: EdgeInsets.all(Design.spacing.sm),
      radius: Design.spacing.radiusXLarge,
      padding: EdgeInsets.all(Design.spacing.md),
      child: SafeArea(
        child: AnimatedPadding(
          duration: Design.timers.short,
          curve: Design.timers.easeInOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: Design.spacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable row inside the attach sheet.
class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AppNeumoSurface(
        radius: Design.spacing.radiusLarge,
        padding: EdgeInsets.all(Design.spacing.md),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: Design.spacing.iconMedium,
                color: colors.primary,
              ),
            ),
            SizedBox(width: Design.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.typo.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.typo.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
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

/// Soft circular composer action (attach).
class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({required this.icon, required this.onTap});

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
        width: 40,
        height: 40,
        padding: EdgeInsets.zero,
        child: Icon(
          icon,
          size: Design.spacing.iconMedium,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

/// Removable chip showing pinned context (an atom) or a picked file.
class _ComposerChip extends StatelessWidget {
  const _ComposerChip({
    required this.icon,
    required this.label,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: EdgeInsets.symmetric(horizontal: Design.spacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: colors.neumo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typo.caption.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Design.icons.close, size: 14, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Row for picking one atom as conversation context.
class _ContextAtomCard extends StatelessWidget {
  const _ContextAtomCard({
    required this.atom,
    required this.onTap,
    this.selected = false,
  });

  final AtomModel atom;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppGlassCard(
      onTap: onTap,
      padding: EdgeInsets.all(Design.spacing.md),
      radius: Design.spacing.radiusLarge,
      // The attached atom wears a soft primary glow so the picker always
      // reflects what the conversation is currently grounded in.
      shadow: selected
          ? <BoxShadow>[
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.30),
                blurRadius: 16,
              ),
            ]
          : null,
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Design.icons.atomAdd,
              size: Design.spacing.iconSmall,
              color: colors.primary,
            ),
          ),
          SizedBox(width: Design.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atom.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.labelMedium.copyWith(
                    color: selected ? colors.primary : colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  [
                    atom.source.toUpperCase(),
                    if ((atom.note ?? '').trim().isNotEmpty)
                      atom.note!.trim().replaceAll('\n', ' '),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Design.spacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Design.icons.check, size: 13, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    AppLocales.ai.selected.tr,
                    style: context.typo.caption.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
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
