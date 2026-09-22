import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

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
            AppLocales.create.title.tr,
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
          AppLocales.create.heading.tr,
          style: context.typo.headline2.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.xs),
        Text(
          AppLocales.create.headingSub.tr,
          style: context.typo.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
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
            title: AppLocales.create.uploadFile.tr,
            child: _buildUploadStage(context),
          ),
        if (controller.selectedMode.value == 'share') _buildShareMode(context),
        if (controller.selectedMode.value == 'note') _buildNoteMode(context),
        // Category attach: admin-managed chips, hidden while none exist or
        // during recording (recordings can be categorized after finishing).
        if (controller.selectedMode.value != 'record')
          _buildCategoryPicker(context),
        SizedBox(height: Design.spacing.xl),
      ],
    );
  }

  /// Tap-to-attach category picker for the atom being created (every user has
  /// their own list); the "＋ New" chip quick-adds a missing category.
  Widget _buildCategoryPicker(BuildContext context) {
    final categoryService = Get.find<CategoryService>();

    return Obx(() {
      final categories = categoryService.categories;

      return Padding(
        padding: EdgeInsets.only(top: Design.spacing.xl),
        child: _SectionShell(
          title: AppLocales.create.category.tr,
          child: Wrap(
            spacing: Design.spacing.sm,
            runSpacing: Design.spacing.sm,
            children: [
              for (final category in categories)
                _CategoryChip(
                  label: category.name,
                  selected: controller.selectedCategoryId.value == category.id,
                  onTap: () => controller.selectCategory(category.id),
                ),
              _CategoryChip(
                label: AppLocales.category.quickAdd.tr,
                leadingIcon: Design.icons.add,
                selected: false,
                onTap: () => _showQuickAddCategory(context),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Admin quick-add: name the category in a small dialog; it is created via
  /// the user endpoint and selected for the atom being created.
  Future<void> _showQuickAddCategory(BuildContext context) async {
    final textController = TextEditingController();
    final name = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        ),
        title: Text(
          AppLocales.category.quickAdd.tr,
          style: context.typo.headline4.copyWith(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: AppLocales.category.nameHint.tr,
          ),
          onSubmitted: (value) => Get.back(result: value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocales.common.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: textController.text.trim()),
            child: Text(AppLocales.category.add.tr),
          ),
        ],
      ),
    );

    final clean = name?.trim() ?? '';
    if (clean.isEmpty) return;
    await controller.quickAddCategory(clean);
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
              AppLocales.create.import.tr,
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

  Widget _buildModePicker(BuildContext context) {
    final colors = context.colors;

    // The strip is a recessed rail; the active mode is the raised thumb.
    return AppNeumoSurface(
      depth: ENeumoDepth.inset,
      radius: 999,
      padding: EdgeInsets.all(4),
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
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: controller.selectedMode.value == mode
                              ? colors.neumoShadowSoft
                              : null,
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
        _ImportActionTile(
          icon: Design.icons.folder,
          title: AppLocales.create.uploadFile.tr,
          subtitle: AppLocales.create.uploadFileSub.tr,
          onTap: () => controller.selectMode('upload'),
        ),
        SizedBox(height: Design.spacing.sm),
        _ImportActionTile(
          icon: Design.icons.note,
          title: AppLocales.create.noteTitle.tr,
          subtitle: AppLocales.create.noteSub.tr,
          onTap: () => controller.selectMode('note'),
        ),
        SizedBox(height: Design.spacing.sm),
        _ImportActionTile(
          icon: Design.icons.shareIos,
          title: AppLocales.create.shareTitle.tr,
          subtitle: AppLocales.create.shareSub.tr,
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
          labels: {
            'preview': AppLocales.create.stagePreview.tr,
            'choose': AppLocales.create.stageChoose.tr,
            'confirm': AppLocales.common.confirm.tr,
          },
          selected: controller.shareStage.value,
          onSelect: controller.selectShareStage,
        ),
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: AppLocales.create.sharedItem.tr,
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
          labels: {
            'draft': AppLocales.create.stageDraft.tr,
            'summary': AppLocales.atom.summary.tr,
            'tasks': AppLocales.ai.resultTasks.tr,
          },
          selected: controller.noteStage.value,
          onSelect: controller.selectNoteStage,
        ),
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: AppLocales.create.noteDraft.tr,
          child: controller.noteStage.value == 'summary'
              ? _buildNoteSummaryStage(context)
              : controller.noteStage.value == 'tasks'
              ? _buildNoteTasksStage(context)
              : _buildNoteDraftStage(context),
        ),
        SizedBox(height: Design.spacing.md),
        _SectionShell(
          title: AppLocales.create.nextSteps.tr,
          child: Column(
            children: [
              _ImportActionTile(
                icon: Design.icons.sparkles,
                title: AppLocales.create.generateSummary.tr,
                subtitle: AppLocales.create.generateSummarySub.tr,
                onTap: () {
                  controller.selectNoteStage('summary');
                  controller.generateNoteSummary();
                },
              ),
              SizedBox(height: Design.spacing.sm),
              _ImportActionTile(
                icon: Design.icons.task,
                title: AppLocales.create.extractTasks.tr,
                subtitle: AppLocales.create.extractTasksSub.tr,
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
        color: colors.neumo,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Import is a picker — each tile leads to its own create flow.
            Obx(
              () => controller.selectedMode.value == 'import'
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(bottom: Design.spacing.sm),
                      child: SizedBox(
                        width: double.infinity,
                        height: Design.spacing.buttonHeight,
                        child: ElevatedButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : _handlePrimaryAction,
                          child: Text(
                            controller.isSubmitting.value
                                ? AppLocales.create.working.tr
                                : _primaryLabel(),
                          ),
                        ),
                      ),
                    ),
            ),
            Obx(
              () => Text(
                controller.selectedMode.value == 'import'
                    ? AppLocales.create.pickSourceHint.tr
                    : controller.selectedMode.value == 'share'
                    ? AppLocales.create.sharedReviewHint.tr
                    : AppLocales.create.draftRefineHint.tr,
                style: context.typo.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: Design.spacing.xs),
            TextButton(
              onPressed: () => AppRoutes.toAi(mode: 'ask'),
              child: Text(
                AppLocales.create.openAsk.tr,
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
        return AppLocales.create.modeRecord.tr;
      case 'import':
        return AppLocales.create.import.tr;
      default:
        return mode;
    }
  }

  String _primaryLabel() {
    switch (controller.selectedMode.value) {
      case 'record':
        return AppLocales.create.addNow.tr;
      case 'upload':
        return AppLocales.create.uploadAndCreate.tr;
      case 'share':
        return controller.shareStage.value == 'confirm'
            ? AppLocales.create.createFromShared.tr
            : AppLocales.create.continueLabel.tr;
      case 'note':
        return controller.noteStage.value == 'tasks'
            ? AppLocales.create.turnTasksIntoAtom.tr
            : AppLocales.create.saveNote.tr;
      default:
        return AppLocales.create.import.tr;
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

  Widget _buildUploadStage(BuildContext context) {
    final colors = context.colors;
    final hasPickedFile = (controller.pickedUploadPath.value ?? '').isNotEmpty;

    return Column(
      // Stretch: without it the drop target hugs its content and sits
      // flush-left with a dead zone on the right (tester: "upload file is
      // not centered"). Full width keeps the box + chip rows centered.
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      AppLocales.create.uploading.tr,
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
                AppNeumoSurface(
                  depth: ENeumoDepth.inset,
                  radius: 999,
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: controller.uploadProgress.value.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: controller.isUploading.value
              ? null
              : controller.pickUploadAsset,
          // Drop target reads as a recess you drop into; a picked file adds a
          // soft primary glow around the well instead of a border.
          child: AnimatedContainer(
            duration: Design.timers.short,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
              boxShadow: hasPickedFile
                  ? <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: AppNeumoSurface(
              depth: ENeumoDepth.inset,
              radius: Design.spacing.radiusXLarge,
              padding: EdgeInsets.all(Design.spacing.xl),
              child: Column(
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasPickedFile ? Design.icons.check : Design.icons.upload,
                      color: colors.primary,
                      size: Design.spacing.iconLarge,
                    ),
                  ),
                  SizedBox(height: Design.spacing.md),
                  Text(
                    hasPickedFile
                        ? (controller.pickedUploadName.value ??
                              AppLocales.create.attachedFile.tr)
                        : AppLocales.create.tapToBrowse.tr,
                    style: context.typo.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Design.spacing.xs),
                  Text(
                    hasPickedFile
                        ? AppLocales.create.readyToUploadHint.tr
                        : AppLocales.create.pickFileHint.tr,
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
        Wrap(
          spacing: Design.spacing.sm,
          runSpacing: Design.spacing.sm,
          alignment: WrapAlignment.center,
          children: [
            _SupportChip(
              icon: Design.icons.audioWave,
              label: AppLocales.create.chipAudio.tr,
            ),
            _SupportChip(
              icon: Design.icons.videoFile,
              label: AppLocales.create.chipVideo.tr,
            ),
            _SupportChip(icon: Design.icons.pictureAsPdf, label: 'PDF'),
            _SupportChip(
              icon: Design.icons.docFile,
              label: AppLocales.create.chipDocuments.tr,
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
          AppLocales.create.captureLive.tr,
          style: context.typo.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.sm),
        Text(
          AppLocales.create.captureLiveSub.tr,
          style: context.typo.bodyMedium.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
        SizedBox(height: Design.spacing.lg),
        _ImportActionTile(
          icon: Design.icons.mic,
          title: AppLocales.create.recordNow.tr,
          subtitle: AppLocales.create.recordNowSub.tr,
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
          AppLocales.create.sharedPayload.tr,
          style: context.typo.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.md),
        AppNeumoSurface(
          depth: ENeumoDepth.inset,
          radius: Design.spacing.radiusLarge,
          padding: EdgeInsets.all(Design.spacing.lg),
          child: TextField(
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            controller: controller.shareTextController,
            minLines: 6,
            maxLines: 10,
            decoration: InputDecoration(
              isDense: true,
              isCollapsed: true,
              hintText: AppLocales.create.pasteSharedHint.tr,
              filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
            ),
            style: context.typo.bodyMedium.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }

  Widget _buildShareChoiceStage(BuildContext context) {
    return Column(
      children: [
        _ImportActionTile(
          icon: Design.icons.clipboard,
          title: AppLocales.create.noteFromShare.tr,
          subtitle: AppLocales.create.noteFromShareSub.tr,
        ),
        SizedBox(height: 12),
        _ImportActionTile(
          icon: Design.icons.sparkles,
          title: AppLocales.create.askAboutThis.tr,
          subtitle: AppLocales.create.askAboutThisSub.tr,
        ),
        SizedBox(height: 12),
        _ImportActionTile(
          icon: Design.icons.folder,
          title: AppLocales.create.attachExisting.tr,
          subtitle: AppLocales.create.attachExistingSub.tr,
        ),
      ],
    );
  }

  Widget _buildShareConfirmStage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocales.create.readyToImport.tr,
          style: context.typo.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Design.spacing.md),
        _ChoiceCard(
          title: AppLocales.create.destination.tr,
          subtitle: AppLocales.create.destinationSub.tr,
        ),
        SizedBox(height: Design.spacing.sm),
        _ChoiceCard(
          title: AppLocales.create.backendRoute.tr,
          subtitle: AppLocales.create.backendRouteSub.tr,
        ),
      ],
    );
  }

  Widget _buildNoteDraftStage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppNeumoSurface(
          depth: ENeumoDepth.inset,
          height: 220,
          radius: Design.spacing.radiusLarge,
          padding: EdgeInsets.all(Design.spacing.lg),
          child: TextField(
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            controller: controller.noteController,
            expands: true,
            minLines: null,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              isDense: true,
              isCollapsed: true,
              filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: AppLocales.create.noteFieldHint.tr,
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
          title: AppLocales.create.generateSummary.tr,
          subtitle: 'Condense the note with AI',
          onTap: controller.generateNoteSummary,
        );
      }
      return AppToneCard(
        title: AppLocales.atom.summary.tr,
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
          title: AppLocales.create.extractTasks.tr,
          subtitle: AppLocales.create.extractTasksSub.tr,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.16)
              : colors.neumo,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: Design.spacing.iconSmall,
                color: selected ? colors.primary : colors.textSecondary,
              ),
              SizedBox(width: Design.spacing.xs),
            ],
            Text(
              label,
              style: context.typo.labelMedium.copyWith(
                color: selected ? colors.primary : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
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
        color: context.colors.textSecondary,
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

class _SupportChip extends StatelessWidget {
  const _SupportChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppNeumoSurface(
      soft: true,
      radius: 999,
      padding: EdgeInsets.symmetric(horizontal: Design.spacing.md, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: Design.spacing.iconSmall,
            color: colors.textSecondary,
          ),
          SizedBox(width: Design.spacing.xs),
          Text(
            label,
            style: context.typo.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
