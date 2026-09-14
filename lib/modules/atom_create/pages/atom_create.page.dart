import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';

import '../controllers/atom_create.controller.dart';

class AtomCreatePage extends GetView<AtomCreateController> {
  const AtomCreatePage({super.key});

  static const _modes = <String>['record', 'import'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppPage(
      backgroundColor: colors.background,
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
            child: _buildTopBar(context),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Design.spacing.screenPadding,
                Design.spacing.xl,
                Design.spacing.screenPadding,
                0,
              ),
              child: Obx(() => _buildBody(context)),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _RoundTopButton(icon: Design.icons.backArrow, onTap: Get.back),
        Expanded(
          child: Text(
            'Create Atom',
            textAlign: TextAlign.center,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _RoundTopButton(icon: Design.icons.close, onTap: Get.back),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      children: [
        Text(
          'Bring anything into AtomicOS',
          style: context.typo.headline2.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.xs),
        Text(
          'Import a link, upload media, or turn shared text into a saved atom.',
          style: context.typo.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: Design.spacing.xl),
        _buildModeHero(context),
        SizedBox(height: Design.spacing.xl),
        if (!_isSubFlow) _buildModePicker(context),
        if (!_isSubFlow) SizedBox(height: Design.spacing.xl),
        if (_isSubFlow) _buildBackRow(context),
        if (controller.selectedMode.value == 'record')
          _buildRecordMode(context),
        if (controller.selectedMode.value == 'import')
          _buildImportMode(context),
        if (controller.selectedMode.value == 'upload')
          _SectionShell(
            title: 'Upload a file',
            child: _buildUploadStage(context),
          ),
        if (controller.selectedMode.value == 'share') _buildShareMode(context),
        if (controller.selectedMode.value == 'note') _buildNoteMode(context),
        SizedBox(height: Design.spacing.xl),
      ],
    );
  }

  bool get _isSubFlow =>
      ['upload', 'share', 'note'].contains(controller.selectedMode.value);

  Widget _buildBackRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Design.spacing.md),
      child: GestureDetector(
        onTap: () => controller.selectMode('import'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Design.icons.backArrow,
              size: Design.spacing.iconSmall,
              color: context.colors.textSecondary,
            ),
            SizedBox(width: Design.spacing.xs),
            Text(
              'Import',
              style: context.typo.labelMedium.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: colors.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Design.spacing.md),
          child: Text(
            'Or',
            style: context.typo.caption.copyWith(color: colors.textMuted),
          ),
        ),
        Expanded(child: Divider(color: colors.border, height: 1)),
      ],
    );
  }

  Widget _buildModePicker(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Obx(
        () => Row(
          children: _modes
              .map(
                (mode) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: mode == _modes.last ? 0 : Design.spacing.xs,
                    ),
                    child: GestureDetector(
                      onTap: () => controller.selectMode(mode),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: Design.spacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: controller.selectedMode.value == mode
                              ? colors.primary
                              : colors.card,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _labelForMode(mode),
                          textAlign: TextAlign.center,
                          style: context.typo.labelMedium.copyWith(
                            color: controller.selectedMode.value == mode
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
      ),
    );
  }

  Widget _buildModeHero(BuildContext context) {
    final colors = context.colors;
    final mode = controller.selectedMode.value;
    final title = switch (mode) {
      'share' => 'Turn shared content into a reviewable atom',
      'note' => 'Draft first, then refine with AI help',
      _ => 'Capture context from links, files, and meetings',
    };
    final subtitle = switch (mode) {
      'share' => 'Shared text can become a note, ask flow, or new atom.',
      'note' => 'Use summary and task stages to shape a better final output.',
      _ => 'Import sources feed the same structured AtomicOS workspace.',
    };

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            ),
            child: Icon(
              mode == 'share'
                  ? Design.icons.shareIos
                  : mode == 'note'
                  ? Design.icons.clipboard
                  : Design.icons.upload,
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
                  style: context.typo.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: Design.spacing.xs),
                Text(
                  subtitle,
                  style: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportMode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionShell(title: 'URL Link', child: _buildYoutubeStage(context)),
        SizedBox(height: Design.spacing.lg),
        _buildOrDivider(context),
        SizedBox(height: Design.spacing.lg),
        _ImportActionTile(
          icon: Design.icons.folder,
          title: 'Upload a file',
          subtitle: 'Audio, Video or documents',
          onTap: () => controller.selectMode('upload'),
        ),
        SizedBox(height: Design.spacing.sm),
        _ImportActionTile(
          icon: Design.icons.note,
          title: 'Note',
          subtitle: 'Manually Type or Paste Text',
          onTap: () => controller.selectMode('note'),
        ),
        SizedBox(height: Design.spacing.sm),
        _ImportActionTile(
          icon: Design.icons.shareIos,
          title: 'Share from another app',
          subtitle: 'Via in-app handoff or share sheet',
          onTap: () => controller.selectMode('share'),
        ),
      ],
    );
  }

  Widget _buildShareMode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStagePicker(
          context,
          labels: const {
            'preview': 'Preview',
            'choose': 'Choose',
            'confirm': 'Confirm',
          },
          selected: controller.shareStage.value,
          onSelect: controller.selectShareStage,
        ),
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: 'Shared item',
          child: controller.shareStage.value == 'choose'
              ? _buildShareChoiceStage(context)
              : controller.shareStage.value == 'confirm'
              ? _buildShareConfirmStage(context)
              : _buildSharePreviewStage(context),
        ),
      ],
    );
  }

  Widget _buildNoteMode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStagePicker(
          context,
          labels: const {
            'draft': 'Draft',
            'summary': 'Summary',
            'tasks': 'Tasks',
          },
          selected: controller.noteStage.value,
          onSelect: controller.selectNoteStage,
        ),
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: 'Note draft',
          child: controller.noteStage.value == 'summary'
              ? _buildNoteSummaryStage(context)
              : controller.noteStage.value == 'tasks'
              ? _buildNoteTasksStage(context)
              : _buildNoteDraftStage(context),
        ),
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: 'Next steps',
          child: Column(
            children: [
              _ImportActionTile(
                icon: Design.icons.sparkles,
                title: 'Generate summary',
                subtitle: 'Create a clean executive version',
                onTap: () {
                  controller.selectNoteStage('summary');
                  controller.generateNoteSummary();
                },
              ),
              SizedBox(height: Design.spacing.sm),
              _ImportActionTile(
                icon: Design.icons.task,
                title: 'Extract tasks',
                subtitle: 'Turn the note into next actions',
                onTap: () {
                  controller.selectNoteStage('tasks');
                  controller.extractNoteTasks();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: Design.spacing.buttonHeight,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : _handlePrimaryAction,
                  child: Text(
                    controller.isSubmitting.value
                        ? 'Working...'
                        : _primaryLabel(),
                  ),
                ),
              ),
            ),
            SizedBox(height: Design.spacing.sm),
            Text(
              controller.selectedMode.value == 'import'
                  ? 'Imported content is converted into a reusable atom workspace.'
                  : controller.selectedMode.value == 'share'
                  ? 'Shared payloads can be reviewed before they are saved.'
                  : 'Draft notes can be refined into summaries and task lists first.',
              style: context.typo.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Design.spacing.xs),
            TextButton(
              onPressed: () => AppRoutes.toAi(mode: 'ask'),
              child: Text(
                'Open Ask AtomicOS',
                style: context.typo.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForMode(String mode) {
    switch (mode) {
      case 'record':
        return 'Record';
      case 'import':
        return 'Import';
      default:
        return mode;
    }
  }

  String _primaryLabel() {
    switch (controller.selectedMode.value) {
      case 'record':
        return 'Add Now';
      case 'upload':
        return 'Upload and create';
      case 'share':
        return controller.shareStage.value == 'confirm'
            ? 'Create from shared text'
            : 'Continue';
      case 'note':
        return controller.noteStage.value == 'tasks'
            ? 'Turn tasks into Atom'
            : 'Save note';
      default:
        return 'Import';
    }
  }

  void _handlePrimaryAction() {
    if (controller.selectedMode.value == 'record') {
      AppRoutes.toLiveActivity();
      return;
    }

    if (controller.selectedMode.value == 'share' &&
        controller.shareStage.value != 'confirm') {
      controller.selectShareStage(
        controller.shareStage.value == 'preview' ? 'choose' : 'confirm',
      );
      return;
    }

    if (controller.selectedMode.value == 'note' &&
        controller.noteStage.value != 'tasks') {
      controller.selectNoteStage(
        controller.noteStage.value == 'draft' ? 'summary' : 'tasks',
      );
      return;
    }

    if (controller.selectedMode.value == 'upload') {
      controller.createFromUpload();
      return;
    }

    if (controller.selectedMode.value == 'note') {
      controller.createFromNote();
      return;
    }

    if (controller.selectedMode.value == 'import') {
      controller.createFromUrl();
      return;
    }

    controller.createFromShare();
  }

  Widget _buildStagePicker(
    BuildContext context, {
    required Map<String, String> labels,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    final colors = context.colors;

    return Wrap(
      spacing: Design.spacing.sm,
      runSpacing: Design.spacing.sm,
      children: labels.entries
          .map(
            (entry) => GestureDetector(
              onTap: () => onSelect(entry.key),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Design.spacing.md,
                  vertical: Design.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: selected == entry.key
                      ? colors.primary.withValues(alpha: 0.14)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected == entry.key
                        ? colors.primary
                        : colors.border,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: context.typo.bodySmall.copyWith(
                    color: selected == entry.key
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

  Widget _buildYoutubeStage(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Design.spacing.md,
        vertical: Design.spacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.urlController,
              decoration: const InputDecoration(
                isDense: true,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Paste youtube URL',
              ),
            ),
          ),
          Icon(
            Design.icons.link,
            size: Design.spacing.iconMedium,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStage(BuildContext context) {
    final colors = context.colors;
    final hasPickedFile = (controller.pickedUploadPath.value ?? '').isNotEmpty;

    return Column(
      children: [
        Obx(() {
          if (!controller.isUploading.value) return const SizedBox.shrink();
          final pct = (controller.uploadProgress.value * 100)
              .clamp(0.0, 100.0)
              .toStringAsFixed(0);
          return Padding(
            padding: EdgeInsets.only(bottom: Design.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Uploading…',
                      style: context.typo.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$pct%',
                      style: context.typo.labelMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Design.spacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: controller.uploadProgress.value.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: colors.card,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: controller.isUploading.value ? null : controller.pickUploadAsset,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Design.icons.upload,
                    color: colors.primary,
                    size: Design.spacing.iconXLarge,
                  ),
                  SizedBox(height: Design.spacing.md),
                  Text(
                    hasPickedFile
                        ? (controller.pickedUploadName.value ?? 'Attached file')
                        : 'Tap to browse device storage',
                    style: context.typo.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Design.spacing.xs),
                  Text(
                    hasPickedFile
                        ? 'Ready to upload and create an atom'
                        : 'Pick a file, image, video, or document',
                    style: context.typo.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Row(
          children: const [
            Expanded(
              child: _ChoiceCard(
                title: 'Audio',
                subtitle: 'Meeting recordings',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _ChoiceCard(
                title: 'Documents',
                subtitle: 'PDF, DOC, slides',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordMode(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add AtomicOS to live meeting',
          style: context.typo.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.sm),
        Text(
          'Drop a meeting link to let AtomicOS capture and summarize it.',
          style: context.typo.bodyMedium.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Design.spacing.md,
            vertical: Design.spacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          child: TextField(
            controller: controller.meetingLinkController,
            decoration: InputDecoration(
              isDense: true,
              isCollapsed: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Enter the meeting link here',
              hintStyle: context.typo.bodyMedium.copyWith(
                color: colors.textMuted,
              ),
            ),
            style: context.typo.bodyMedium,
          ),
        ),
        SizedBox(height: Design.spacing.lg),
        _buildOrDivider(context),
        SizedBox(height: Design.spacing.lg),
        _ImportActionTile(
          icon: Design.icons.mic,
          title: 'Record Now',
          subtitle: 'Start capturing audio with AtomicOS',
          onTap: AppRoutes.toLiveActivity,
        ),
      ],
    );
  }

  Widget _buildSharePreviewStage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shared payload',
          style: context.typo.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.md),
        TextField(
          controller: controller.shareTextController,
          minLines: 6,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Paste shared text here...',
            border: InputBorder.none,
          ),
          style: context.typo.bodyMedium.copyWith(height: 1.45),
        ),
      ],
    );
  }

  Widget _buildShareChoiceStage(BuildContext context) {
    return Column(
      children: [
        _ImportActionTile(
          icon: Design.icons.clipboard,
          title: 'Create note from share',
          subtitle: 'Convert the raw text into a structured note',
        ),
        SizedBox(height: 12),
        _ImportActionTile(
          icon: Design.icons.sparkles,
          title: 'Ask AtomicOS about this',
          subtitle: 'Generate summary, decisions, and tasks',
        ),
        SizedBox(height: 12),
        _ImportActionTile(
          icon: Design.icons.folder,
          title: 'Attach to existing Atom',
          subtitle: 'Merge with a previous meeting workspace',
        ),
      ],
    );
  }

  Widget _buildShareConfirmStage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to import',
          style: context.typo.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.md),
        const _ChoiceCard(
          title: 'Destination',
          subtitle: 'New atom from shared text',
        ),
        SizedBox(height: Design.spacing.sm),
        const _ChoiceCard(
          title: 'Backend route',
          subtitle: 'Creates via POST /v1/atoms/from-share',
        ),
      ],
    );
  }

  Widget _buildNoteDraftStage(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
          ),
          child: TextField(
            controller: controller.noteController,
            expands: true,
            minLines: null,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              isDense: true,
              isCollapsed: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Type or paste a note...',
            ),
            style: context.typo.bodyMedium.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSummaryStage(BuildContext context) {
    return Obx(() {
      if (controller.isGeneratingSummary.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(Design.spacing.lg),
            child: const CircularProgressIndicator(),
          ),
        );
      }
      final summary = controller.noteSummary.value;
      if (summary == null || summary.isEmpty) {
        return _ImportActionTile(
          icon: Design.icons.sparkles,
          title: 'Generate summary',
          subtitle: 'Condense the note with AI',
          onTap: controller.generateNoteSummary,
        );
      }
      return AppToneCard(
        title: 'Summary',
        subtitle: summary,
        tone: EAppToneCardTone.primary,
      );
    });
  }

  Widget _buildNoteTasksStage(BuildContext context) {
    return Obx(() {
      if (controller.isExtractingTasks.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(Design.spacing.lg),
            child: const CircularProgressIndicator(),
          ),
        );
      }
      final tasks = controller.noteTaskItems;
      if (tasks.isEmpty) {
        return _ImportActionTile(
          icon: Design.icons.task,
          title: 'Extract tasks',
          subtitle: 'Turn the note into next actions',
          onTap: controller.extractNoteTasks,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tasks
            .map(
              (task) => Padding(
                padding: EdgeInsets.only(bottom: Design.spacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Design.icons.check,
                      size: 16,
                      color: context.colors.primary,
                    ),
                    SizedBox(width: Design.spacing.sm),
                    Expanded(
                      child: Text(
                        task,
                        style: context.typo.bodyMedium.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    });
  }
}

class _RoundTopButton extends StatelessWidget {
  const _RoundTopButton({required this.icon, required this.onTap});

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

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: EdgeInsets.all(Design.spacing.lg),
      radius: Design.spacing.radiusXLarge,
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

class _ImportActionTile extends StatelessWidget {
  const _ImportActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppToneCard(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      tone: EAppToneCardTone.primary,
      trailing: Icon(
        Design.icons.rightArrow,
        size: Design.spacing.iconMedium,
        color: context.colors.textMuted,
      ),
      onTap: onTap,
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppToneCard(
      title: title,
      subtitle: subtitle,
      tone: EAppToneCardTone.neutral,
    );
  }
}
