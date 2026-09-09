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
        _RoundTopButton(
          icon: Design.icons.backArrow,
          onTap: Get.back,
        ),
        Expanded(
          child: Text(
            'Create Atom',
            textAlign: TextAlign.center,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _RoundTopButton(
          icon: Design.icons.close,
          onTap: Get.back,
        ),
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
          'Mock the import, share, and note flows before backend wiring.',
          style: context.typo.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: Design.spacing.xl),
        _buildModePicker(context),
        SizedBox(height: Design.spacing.xl),
        if (controller.selectedMode.value == 'import') _buildImportMode(context),
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
          title: 'Queued items',
          child: Column(
            children: [
              if (controller.importStage.value == 'youtube')
                const _QueuedImportCard(
                  source: 'YOUTUBE',
                  title: 'Myanmar market trends 2026 - weekly briefing',
                  status: 'Processing preview',
                ),
              if (controller.importStage.value == 'upload')
                const _QueuedImportCard(
                  source: 'UPLOAD',
                  title: 'Sprint review memo.pdf',
                  status: 'Ready to attach',
                ),
              if (controller.importStage.value == 'meeting')
                const _QueuedImportCard(
                  source: 'MEETING',
                  title: 'Marketing sync · live capture',
                  status: 'Ready to join',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareMode(BuildContext context) {
    final colors = context.colors;

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
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: 'Preview',
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            ),
            child: Center(
              child: Icon(
                Design.icons.attachment,
                color: colors.textMuted,
                size: Design.spacing.iconXLarge,
              ),
            ),
          ),
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
              ),
              SizedBox(height: Design.spacing.sm),
              _ImportActionTile(
                icon: Design.icons.task,
                title: 'Extract tasks',
                subtitle: 'Turn the note into next actions',
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
              child: ElevatedButton(
                onPressed: _handlePrimaryAction,
                child: Text(_primaryLabel()),
              ),
            ),
            SizedBox(height: Design.spacing.sm),
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
            ? 'Create shared Atom'
            : 'Continue';
      case 'note':
        return controller.noteStage.value == 'tasks'
            ? 'Turn tasks into Atom'
            : 'Save note';
      default:
        return controller.importStage.value == 'meeting'
            ? 'Join live meeting'
            : 'Import';
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
      AppRoutes.toAi(mode: 'details');
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

    AppRoutes.toAi(mode: 'details');
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
            borderRadius: BorderRadius.circular(
              Design.spacing.radiusLarge,
            ),
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
        ),
        SizedBox(height: Design.spacing.sm),
        _ImportActionTile(
          icon: Design.icons.shareIos,
          title: 'Share from another app',
          subtitle: 'In-app handoff or OS share sheet',
        ),
        SizedBox(height: Design.spacing.sm),
        _ImportActionTile(
          icon: Design.icons.clipboard,
          title: 'Paste note',
          subtitle: 'Transform raw text into an Atom',
        ),
      ],
    );
  }

  Widget _buildUploadStage(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Container(
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
                  'Drop files here or browse device storage',
                  style: context.typo.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Design.spacing.xs),
                Text(
                  'Supports audio, video, docs, and PDFs',
                  style: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
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
              Wrap(
                spacing: Design.spacing.xs,
                runSpacing: Design.spacing.xs,
                children: const [
                  _MiniMetaChip(label: 'SLACK'),
                  _MiniMetaChip(label: 'Marketing'),
                  _MiniMetaChip(label: 'Live capture'),
                ],
              ),
              SizedBox(height: Design.spacing.md),
              Text(
                'Add AtomicOS to live meeting',
                style: context.typo.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Design.spacing.sm),
              Text(
                'Preview the handoff into the meeting workspace.',
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
                title: 'Join Slack huddle',
                subtitle: '3 speakers detected',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _ChoiceCard(
                title: 'Open recorder',
                subtitle: 'Prepare meeting note',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSharePreviewStage(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(
              Design.spacing.radiusLarge,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Design.spacing.xs,
                runSpacing: Design.spacing.xs,
                children: const [
                  _MiniMetaChip(label: 'SLACK'),
                  _MiniMetaChip(label: 'Meeting note'),
                  _MiniMetaChip(label: '3 attachments'),
                ],
              ),
              SizedBox(height: Design.spacing.md),
              Text(
                'Product launch retrospective',
                style: context.typo.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Design.spacing.sm),
              Text(
                'Choose whether this shared payload becomes a note, an atom, or an AI prompt.',
                style: context.typo.bodyMedium.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.md),
        Row(
          children: const [
            Expanded(
              child: _ChoiceCard(
                title: 'Create note',
                subtitle: 'Keep the raw text',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _ChoiceCard(
                title: 'Ask AI',
                subtitle: 'Generate actions',
              ),
            ),
          ],
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
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to import',
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Design.spacing.md),
          const _ChoiceCard(
            title: 'Destination',
            subtitle: 'New shared Atom',
          ),
          SizedBox(height: Design.spacing.sm),
          const _ChoiceCard(
            title: 'AI actions',
            subtitle: 'Summary, tasks, report',
          ),
        ],
      ),
    );
  }

  Widget _buildNoteDraftStage(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Design.spacing.xs,
          runSpacing: Design.spacing.xs,
          children: const [
            _MiniMetaChip(label: 'SUMMARY'),
            _MiniMetaChip(label: 'TASKS'),
            _MiniMetaChip(label: 'PERSONAL'),
          ],
        ),
        SizedBox(height: Design.spacing.md),
        Container(
          height: 220,
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(
              Design.spacing.radiusLarge,
            ),
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
    return Column(
      children: const [
        _ChoiceCard(
          title: 'Executive summary',
          subtitle: 'Solar System note condensed into 4 key bullets',
        ),
        SizedBox(height: 12),
        _ChoiceCard(
          title: 'Key insight',
          subtitle: 'Scientists tracked the solar nebula collapse timeline',
        ),
      ],
    );
  }

  Widget _buildNoteTasksStage(BuildContext context) {
    return Column(
      children: [
        _ImportActionTile(
          icon: Design.icons.task,
          title: 'Review research assumptions',
          subtitle: 'Assign owner and target completion date',
        ),
        SizedBox(height: 12),
        _ImportActionTile(
          icon: Design.icons.task,
          title: 'Prepare follow-up memo',
          subtitle: 'Summarize the note for the next sync',
        ),
      ],
    );
  }
}

class _RoundTopButton extends StatelessWidget {
  const _RoundTopButton({
    required this.icon,
    required this.onTap,
  });

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
  const _SectionShell({
    required this.title,
    required this.child,
  });

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
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
    final colors = context.colors;

    return AppToneCard(
      title: title,
      subtitle: status,
      eyebrow: source,
      tone: EAppToneCardTone.primary,
      footer: LinearProgressIndicator(
        value: 0.62,
        minHeight: 6,
        borderRadius: BorderRadius.circular(999),
        backgroundColor: colors.card,
        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
      ),
    );
  }
}

class _MiniMetaChip extends StatelessWidget {
  const _MiniMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Design.spacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.typo.caption.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
  });

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
