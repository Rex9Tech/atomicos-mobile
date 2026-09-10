import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';

import '../controllers/atom_create.controller.dart';

class AtomCreatePage extends GetView<AtomCreateController> {
  const AtomCreatePage({super.key});

  static const _modes = <String>['import', 'share', 'note'];

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
        _buildModePicker(context),
        SizedBox(height: Design.spacing.xl),
        if (controller.selectedMode.value == 'import')
          _buildImportMode(context),
        if (controller.selectedMode.value == 'share') _buildShareMode(context),
        if (controller.selectedMode.value == 'note') _buildNoteMode(context),
        SizedBox(height: Design.spacing.xl),
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
        _buildStagePicker(
          context,
          labels: const {
            'youtube': 'YouTube',
            'upload': 'Upload',
            'meeting': 'Live meeting',
          },
          selected: controller.importStage.value,
          onSelect: controller.selectImportStage,
        ),
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: 'Import source',
          child: controller.importStage.value == 'upload'
              ? _buildUploadStage(context)
              : controller.importStage.value == 'meeting'
              ? _buildMeetingStage(context)
              : _buildYoutubeStage(context),
        ),
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: 'Queued item',
          child: Obx(() {
            final stage = controller.importStage.value;
            final String title;
            final String status;
            if (stage == 'upload') {
              final name = controller.pickedUploadName.value;
              title = name ?? 'No file selected';
              status = name == null
                  ? 'Tap the upload area to pick a file'
                  : 'Ready to upload and create';
            } else if (stage == 'meeting') {
              title = 'Live meeting';
              status = 'Join to start capturing audio';
            } else {
              final url = controller.urlText.value.trim();
              title = url.isEmpty ? 'No link yet' : url;
              status = url.isEmpty
                  ? 'Paste a YouTube URL above'
                  : 'Will import and summarize';
            }
            return _QueuedImportCard(
              source: stage.toUpperCase(),
              title: title,
              status: status,
            );
          }),
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
      case 'share':
        return 'Share';
      case 'note':
        return 'Note';
      default:
        return 'Import';
    }
  }

  String _primaryLabel() {
    switch (controller.selectedMode.value) {
      case 'share':
        return controller.shareStage.value == 'confirm'
            ? 'Create from shared text'
            : 'Continue';
      case 'note':
        return controller.noteStage.value == 'tasks'
            ? 'Turn tasks into Atom'
            : 'Save note';
      default:
        if (controller.importStage.value == 'meeting') {
          return 'Join live meeting';
        }
        if (controller.importStage.value == 'upload') {
          return 'Upload and create';
        }
        return 'Import';
    }
  }

  void _handlePrimaryAction() {
    if (controller.selectedMode.value == 'import' &&
        controller.importStage.value == 'meeting') {
      AppRoutes.toAi(mode: 'meeting');
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

    if (controller.selectedMode.value == 'import' &&
        controller.importStage.value == 'upload') {
      controller.createFromUpload();
      return;
    }

    // Final step: actually create the atom.
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

    return Column(
      children: [
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
        ),
        SizedBox(height: Design.spacing.md),
        _ImportActionTile(
          icon: Design.icons.folder,
          title: 'Upload a file',
          subtitle: 'Audio, video, PDFs, or documents',
          onTap: () => controller.selectImportStage('upload'),
        ),
        SizedBox(height: Design.spacing.sm),
        _ImportActionTile(
          icon: Design.icons.shareIos,
          title: 'Share from another app',
          subtitle: 'In-app handoff or OS share sheet',
          onTap: () => controller.selectMode('share'),
        ),
        SizedBox(height: Design.spacing.sm),
        _ImportActionTile(
          icon: Design.icons.clipboard,
          title: 'Paste note',
          subtitle: 'Transform raw text into an Atom',
          onTap: () => controller.selectMode('note'),
        ),
      ],
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

  Widget _buildMeetingStage(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a live meeting',
                style: context.typo.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Design.spacing.sm),
              Text(
                'Record audio, then finish to generate a summarized atom from the transcript.',
                style: context.typo.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Row(
          children: const [
            Expanded(
              child: _ChoiceCard(
                title: 'Record meeting',
                subtitle: 'Capture audio + transcript',
              ),
            ),
          ],
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
    return AppCard(
      padding: EdgeInsets.all(Design.spacing.lg),
      borderRadius: Design.spacing.radiusXLarge,
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

class _QueuedImportCard extends StatelessWidget {
  const _QueuedImportCard({
    required this.source,
    required this.title,
    required this.status,
  });

  final String source;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppToneCard(
      title: title,
      subtitle: status,
      eyebrow: source,
      tone: EAppToneCardTone.primary,
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
