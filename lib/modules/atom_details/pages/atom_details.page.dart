import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/atom_details.controller.dart';

class AtomDetailsPage extends GetView<AtomDetailsController> {
  const AtomDetailsPage({super.key});

  List<String> get _tabs => [
    AppLocales.atom.summary.tr,
    AppLocales.atom.transcript.tr,
    AppLocales.atom.note.tr,
    AppLocales.atom.assets.tr,
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      backgroundColor: context.colors.background,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final atom = controller.atom.value;
              if (atom == null || controller.hasError.value) {
                return Padding(
                  padding: EdgeInsets.all(Design.spacing.screenPadding),
                  child: _buildError(context),
                );
              }
              return _buildContent(context, atom);
            }),
          ),
          Obx(() {
            final atom = controller.atom.value;
            if (atom == null || controller.hasError.value) {
              return const SizedBox.shrink();
            }
            return _buildBottomBar(context, atom);
          }),
        ],
      ),
    );
  }

  // ===== Top bar: back · Details · more =====

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Design.icons.backArrow, onTap: Get.back),
        Expanded(
          child: Text(
            AppLocales.ai.detailsTab.tr,
            textAlign: TextAlign.center,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _CircleButton(
          icon: Design.icons.more,
          onTap: () => _showActions(context),
        ),
      ],
    );
  }

  void _showActions(BuildContext context) {
    final atom = controller.atom.value;
    if (atom == null) return;

    Get.bottomSheet<void>(
      AppNeumoSurface(
        margin: EdgeInsets.all(Design.spacing.sm),
        radius: Design.spacing.radiusXLarge,
        padding: EdgeInsets.all(Design.spacing.lg),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetAction(
                icon: Design.icons.edit,
                label: AppLocales.common.rename.tr,
                onTap: () {
                  Get.back();
                  _promptRename(context, atom);
                },
              ),
              SizedBox(height: Design.spacing.sm),
              _SheetAction(
                icon: Design.icons.category,
                label: AppLocales.atom.setCategory.tr,
                onTap: () {
                  Get.back();
                  _pickCategory(context, atom);
                },
              ),
              SizedBox(height: Design.spacing.sm),
              _SheetAction(
                icon: Design.icons.clipboard,
                label: AppLocales.atom.copy.tr,
                onTap: () {
                  Get.back();
                  _copyAtom(atom);
                },
              ),
              SizedBox(height: Design.spacing.sm),
              _SheetAction(
                icon: Design.icons.sparkles,
                label: AppLocales.ai.askAboutThisAtom.tr,
                onTap: () {
                  Get.back();
                  AppRoutes.toAi(
                    mode: 'ask',
                    atomId: atom.id,
                    atomTitle: atom.title,
                  );
                },
              ),
              SizedBox(height: Design.spacing.sm),
              _SheetAction(
                icon: Design.icons.calendar,
                label: AppLocales.calendar.title.tr,
                onTap: () {
                  Get.back();
                  AppRoutes.toCalendar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Category picker — 'No category' plus the current user's own list, with
  /// the atom's current choice checked. Mirrors the create-flow picker.
  void _pickCategory(BuildContext context, AtomModel atom) {
    final categoryService = Get.find<CategoryService>();

    Get.bottomSheet<void>(
      AppNeumoSurface(
        margin: EdgeInsets.all(Design.spacing.sm),
        radius: Design.spacing.radiusXLarge,
        padding: EdgeInsets.all(Design.spacing.lg),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocales.category.selectTitle.tr,
                  style: context.typo.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Design.spacing.lg),
                Flexible(
                  child: SingleChildScrollView(
                    child: Obx(
                      () => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SheetAction(
                            icon: Design.icons.close,
                            label: AppLocales.category.none.tr,
                            selected: atom.categoryId == null,
                            onTap: () async {
                              Get.back();
                              await controller.updateCategory(null);
                            },
                          ),
                          for (final category
                              in categoryService.categories) ...[
                            SizedBox(height: Design.spacing.sm),
                            _SheetAction(
                              icon: Design.icons.category,
                              label: category.name,
                              selected: atom.categoryId == category.id,
                              onTap: () async {
                                Get.back();
                                await controller.updateCategory(category.id);
                              },
                            ),
                          ],
                          if (categoryService.categories.isEmpty) ...[
                            SizedBox(height: Design.spacing.md),
                            Text(
                              AppLocales.category.empty.tr,
                              textAlign: TextAlign.center,
                              style: context.typo.caption.copyWith(
                                color: context.colors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tappable chip showing the atom's category — hidden while uncategorized
  /// or until the category list resolves it.
  Widget _buildCategoryChip(BuildContext context, AtomModel atom) {
    final categoryService = Get.find<CategoryService>();

    return Obx(() {
      // Force a read on every build — byId short-circuits when categoryId
      // is null and would otherwise leave this Obx with no Rx dependency.
      final categories = categoryService.categories.toList();
      final id = atom.categoryId;
      CategoryModel? category;
      if (id != null && id.isNotEmpty) {
        for (final item in categories) {
          if (item.id == id) {
            category = item;
            break;
          }
        }
      }
      if (category == null) return const SizedBox.shrink();
      final colors = context.colors;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: Design.spacing.sm),
          Icon(Design.icons.category, size: 13, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            category.name,
            style: context.typo.caption.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    });
  }

  // ===== Content =====

  Widget _buildContent(BuildContext context, AtomModel atom) {
    final hasAudio = controller.audioUrl.value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Design.spacing.screenPadding,
            Design.spacing.lg,
            Design.spacing.screenPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMeta(context, atom),
              if (hasAudio) ...[
                SizedBox(height: Design.spacing.lg),
                _buildPlayerCard(context),
              ],
              SizedBox(height: Design.spacing.lg),
              _buildTabs(context, atom),
            ],
          ),
        ),
        SizedBox(height: Design.spacing.lg),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Design.spacing.screenPadding,
            ),
            child: _buildTabBody(context, atom),
          ),
        ),
      ],
    );
  }

  Widget _buildMeta(BuildContext context, AtomModel atom) {
    final colors = context.colors;
    final duration = _compactDuration(atom.durationSecs);
    final speakers = atom.participantsCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _sourceIcon(atom.source),
              size: Design.spacing.iconSmall,
              color: colors.textSecondary,
            ),
            SizedBox(width: Design.spacing.xs),
            Text(
              atom.source.toUpperCase(),
              style: context.typo.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (speakers > 0) ...[
              SizedBox(width: Design.spacing.sm),
              Text(
                '$speakers speakers',
                style: context.typo.caption.copyWith(color: colors.textMuted),
              ),
            ],
          ],
        ),
        SizedBox(height: Design.spacing.sm),
        Text(
          atom.title,
          style: context.typo.headline3.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        SizedBox(height: Design.spacing.sm),
        Obx(() {
          final meetingAt = controller.meetingAt.value;
          final linked = controller.linkedEvent.value != null;
          return Row(
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: controller.isSavingDate.value
                      ? null
                      : () => _pickMeetingDate(context),
                  child: AppNeumoSurface(
                    soft: true,
                    radius: 999,
                    padding: EdgeInsets.symmetric(
                      horizontal: Design.spacing.sm,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.isSavingDate.value)
                          SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        else
                          Icon(
                            Design.icons.calendar,
                            size: 13,
                            color: colors.primary,
                          ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            meetingAt == null
                                ? AppLocales.atom.setMeetingDate.tr
                                : _dateTimeLabel(context, meetingAt),
                            overflow: TextOverflow.ellipsis,
                            style: context.typo.caption.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Design.icons.edit,
                          size: 12,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (duration.isNotEmpty) ...[
                SizedBox(width: Design.spacing.sm),
                Icon(Design.icons.clock, size: 13, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: context.typo.caption.copyWith(color: colors.textMuted),
                ),
              ],
              _buildCategoryChip(context, atom),
              if (linked) ...[
                SizedBox(width: Design.spacing.sm),
                Icon(Design.icons.check, size: 13, color: colors.primary),
                const SizedBox(width: 3),
                Text(
                  AppLocales.atom.inPlanner.tr,
                  style: context.typo.caption.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  // ===== Player card (the atom's source recording) =====

  Widget _buildPlayerCard(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final total = controller.duration.value;
      final pos = controller.position.value;
      final progress = total.inMilliseconds > 0
          ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      return AppGlassCard(
        padding: EdgeInsets.all(Design.spacing.md),
        radius: Design.spacing.radiusLarge,
        child: Column(
          children: [
            AppNeumoSurface(
              depth: ENeumoDepth.inset,
              soft: true,
              radius: 999,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: double.infinity,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ),
            ),
            SizedBox(height: Design.spacing.md),
            Row(
              children: [
                GestureDetector(
                  onTap: controller.togglePlayback,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.isPlaying.value
                          ? Design.icons.pause
                          : Design.icons.play,
                      size: Design.spacing.iconMedium,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
                SizedBox(width: Design.spacing.md),
                _CircleButton(
                  icon: Design.icons.replay10,
                  size: 32,
                  onTap: () => controller.skip(-10),
                ),
                SizedBox(width: Design.spacing.sm),
                _CircleButton(
                  icon: Design.icons.forward10,
                  size: 32,
                  onTap: () => controller.skip(10),
                ),
                const Spacer(),
                Text(
                  '${_timecode(pos)}/${_timecode(total)}',
                  style: context.typo.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ===== Tabs =====

  /// Tabs that actually have content, in canonical order:
  /// 0 Summary · 1 Transcript · 2 Note · 3 Assets. Empty Summary/Transcript
  /// tabs are hidden — testers asked for note atoms to drop them.
  List<int> _visibleTabIndexes(AtomModel atom) => [
    if (atom.summaryBlocks.isNotEmpty) 0,
    if (atom.transcriptSegments.isNotEmpty) 1,
    2,
    3,
  ];

  int _effectiveTab(AtomModel atom) {
    final visible = _visibleTabIndexes(atom);
    final active = controller.activeTab.value;
    if (visible.contains(active)) return active;
    return 2; // Note is always available.
  }

  Widget _buildTabs(BuildContext context, AtomModel atom) {
    final colors = context.colors;
    final visible = _visibleTabIndexes(atom);

    // The strip is a recessed rail; the active tab is the raised thumb.
    return Obx(
      () => AppNeumoSurface(
        depth: ENeumoDepth.inset,
        radius: 999,
        padding: EdgeInsets.all(4),
        child: Row(
          children: visible.map((index) {
            final label = _tabs[index];
            final selected = _effectiveTab(atom) == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == visible.last ? 0 : Design.spacing.xs,
                ),
                child: GestureDetector(
                  onTap: () => controller.selectTab(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: Design.spacing.sm),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: selected ? colors.neumoShadowSoft : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: context.typo.labelMedium.copyWith(
                        color: selected
                            ? colors.onPrimary
                            : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabBody(BuildContext context, AtomModel atom) {
    return Obx(() {
      switch (_effectiveTab(atom)) {
        case 1:
          return _buildTranscript(context, atom);
        case 2:
          return _buildNote(context, atom);
        case 3:
          return _buildAssets(context, atom);
        default:
          return _buildSummary(context, atom);
      }
    });
  }

  Widget _buildSummary(BuildContext context, AtomModel atom) {
    final blocks = _summaryMarkdownBlocks(atom.summaryBlocks);
    if (blocks.isEmpty) {
      return _emptyState(context, AppLocales.atom.noSummary.tr);
    }
    return _scrollableCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final text = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == blocks.length - 1 ? 0 : Design.spacing.lg,
            ),
            child: _markdown(context, text),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTranscript(BuildContext context, AtomModel atom) {
    if (atom.transcriptSegments.isEmpty) {
      return _emptyState(context, AppLocales.atom.noTranscript.tr);
    }
    return _scrollableCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: atom.transcriptSegments.map((segment) {
          final text = _segmentText(segment);
          return Padding(
            padding: EdgeInsets.only(bottom: Design.spacing.sm),
            child: Text(
              text,
              style: context.typo.bodyMedium.copyWith(height: 1.4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNote(BuildContext context, AtomModel atom) {
    final note = atom.note?.trim();
    if (note == null || note.isEmpty) {
      return _emptyState(context, AppLocales.atom.noNote.tr);
    }
    return _scrollableCard(context, _markdown(context, note));
  }

  // ===== Assets: supporting files (source recording excluded) =====

  Widget _buildAssets(BuildContext context, AtomModel atom) {
    final colors = context.colors;
    final files = controller.attachments;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (files.isEmpty)
            AppGlassCard(
              padding: EdgeInsets.all(Design.spacing.xl),
              radius: Design.spacing.radiusXLarge,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Design.icons.folder,
                          size: 44,
                          color: colors.textMuted,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: colors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Design.icons.add,
                              size: 14,
                              color: colors.onWarning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Design.spacing.md),
                  Text(
                    AppLocales.ai.noAssets.tr,
                    style: context.typo.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: Design.spacing.xs),
                  Text(
                    AppLocales.atom.addFilesHint.tr,
                    textAlign: TextAlign.center,
                    style: context.typo.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...files.map(
              (asset) => Padding(
                padding: EdgeInsets.only(bottom: Design.spacing.sm),
                child: _buildAssetCard(context, asset),
              ),
            ),
          SizedBox(height: Design.spacing.sm),
          GestureDetector(
            onTap: controller.isUploadingAsset.value
                ? null
                : controller.addAttachment,
            // Upload zone, not a card — it should read as a recess.
            child: AppNeumoSurface(
              depth: ENeumoDepth.inset,
              radius: Design.spacing.radiusLarge,
              padding: EdgeInsets.symmetric(vertical: Design.spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.isUploadingAsset.value)
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  else
                    Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: colors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Design.icons.add,
                        size: 14,
                        color: colors.onWarning,
                      ),
                    ),
                  SizedBox(width: Design.spacing.sm),
                  Text(
                    files.isEmpty
                        ? AppLocales.atom.addFiles.tr
                        : AppLocales.ai.addMoreFiles.tr,
                    style: context.typo.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, AtomAssetModel asset) {
    final colors = context.colors;
    final accent = _assetAccent(context, asset);
    final size = _formatBytes(asset.sizeBytes);
    final ext = (asset.format.isNotEmpty ? asset.format : asset.type)
        .toUpperCase();

    return AppGlassCard(
      onTap: () => _openAsset(asset),
      padding: EdgeInsets.all(Design.spacing.md),
      radius: Design.spacing.radiusLarge,
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _assetIcon(asset),
              size: Design.spacing.iconMedium,
              color: accent,
            ),
          ),
          SizedBox(width: Design.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.labelMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  [
                    if (size.isNotEmpty) size,
                    if (ext.isNotEmpty) ext,
                  ].join(' . '),
                  style: context.typo.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Bottom bar: history · Ask about this Atom =====

  Widget _buildBottomBar(BuildContext context, AtomModel atom) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Design.spacing.screenPadding,
        Design.spacing.sm,
        Design.spacing.screenPadding,
        Design.spacing.lg,
      ),
      child: Row(
        children: [
          _CircleButton(
            icon: Design.icons.history,
            size: 40,
            onTap: AppRoutes.toCalendar,
          ),
          SizedBox(width: Design.spacing.md),
          Expanded(
            child: GestureDetector(
              onTap: () => AppRoutes.toAi(
                mode: 'ask',
                atomId: atom.id,
                atomTitle: atom.title,
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Design.icons.sparkles,
                      size: Design.spacing.iconSmall,
                      color: colors.onPrimary,
                    ),
                    SizedBox(width: Design.spacing.xs),
                    Text(
                      AppLocales.ai.askAboutThisAtom.tr,
                      style: context.typo.labelMedium.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Small pieces =====

  Future<void> _copyAtom(AtomModel atom) async {
    final parts = <String>[
      atom.title,
      if ((atom.note ?? '').trim().isNotEmpty) atom.note!.trim(),
      ..._summaryMarkdownBlocks(atom.summaryBlocks),
    ].where((e) => e.isNotEmpty);

    await Clipboard.setData(ClipboardData(text: parts.join('\n\n')));
    AppSnackbar.success(AppLocales.atom.copiedToClipboard.tr);
  }

  Future<void> _promptRename(BuildContext context, AtomModel atom) async {
    final textController = TextEditingController(text: atom.title);
    final next = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        ),
        title: Text(
          AppLocales.common.rename.tr,
          style: context.typo.headline4.copyWith(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: AppLocales.atom.name.tr),
          onSubmitted: (value) => Get.back(result: value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocales.common.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: textController.text.trim()),
            child: Text(AppLocales.common.save.tr),
          ),
        ],
      ),
    );

    final clean = next?.trim() ?? '';
    if (clean.isEmpty || clean == atom.title) return;
    await controller.renameAtom(clean);
  }

  Future<void> _openAsset(AtomAssetModel asset) async {
    final uri = Uri.tryParse(asset.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _scrollableCard(BuildContext context, Widget child) {
    return SingleChildScrollView(
      // Let the card take the scroll view's max width without forcing
      // double.infinity through AppNeumoSurface (that can blow layout).
      child: SizedBox(
        width: double.infinity,
        child: AppGlassCard(
          padding: EdgeInsets.all(Design.spacing.lg),
          radius: Design.spacing.radiusXLarge,
          child: child,
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    final colors = context.colors;

    return AppGlassCard(
      padding: EdgeInsets.all(Design.spacing.xl),
      radius: Design.spacing.radiusXLarge,
      child: Column(
        children: [
          Icon(Design.icons.emptyBox, size: 36, color: colors.textMuted),
          SizedBox(height: Design.spacing.md),
          Text(
            AppLocales.atom.nothingHere.tr,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Design.spacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.typo.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = context.colors;

    return AppToneCard(
      title: AppLocales.atom.loadFailed.tr,
      subtitle: AppLocales.atom.pullToRetry.tr,
      leadingIcon: Design.icons.warning,
      tone: EAppToneCardTone.error,
      footer: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: controller.loadAtom,
          child: Text(
            AppLocales.atom.retry.tr,
            style: context.typo.labelMedium.copyWith(color: colors.error),
          ),
        ),
      ),
    );
  }

  // ===== Formatting / mapping helpers =====

  IconData _sourceIcon(String source) {
    switch (source.toLowerCase()) {
      case 'url':
        return Design.icons.link;
      case 'share':
        return Design.icons.shareIos;
      case 'asset':
        return Design.icons.mic;
      case 'meeting':
        return Design.icons.mic;
      default:
        return Design.icons.note;
    }
  }

  IconData _assetIcon(AtomAssetModel asset) {
    final format = asset.format.toLowerCase();
    final name = asset.name.toLowerCase();
    if (format == 'image') return Design.icons.imageFile;
    if (format == 'video') return Design.icons.videoFile;
    if (format == 'audio') return Design.icons.audioWave;
    if (name.endsWith('.pdf')) return Design.icons.pictureAsPdf;
    return Design.icons.docFile;
  }

  Color _assetAccent(BuildContext context, AtomAssetModel asset) {
    final colors = context.colors;
    final format = asset.format.toLowerCase();
    if (format == 'image') return colors.info;
    if (format == 'video') return colors.primary;
    if (format == 'audio') return colors.warning;
    if (asset.name.toLowerCase().endsWith('.pdf')) return colors.error;
    return colors.primary;
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
    return '$bytes B';
  }

  String _timecode(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _pickMeetingDate(BuildContext context) async {
    final current = controller.meetingAt.value ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 3, 12, 31),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!context.mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    );
    await controller.saveMeetingDate(picked);
  }

  String _dateTimeLabel(BuildContext context, DateTime value) {
    final l10n = MaterialLocalizations.of(context);
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '${l10n.formatShortMonthDay(value)} · $hh:$mm';
  }

  String _compactDuration(int? secs) {
    if (secs == null || secs <= 0) return '';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${secs}s';
  }

  List<String> _summaryMarkdownBlocks(List<dynamic> blocks) {
    return blocks
        .map(_extractMarkdownText)
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  String _extractMarkdownText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return value
          .map(_extractMarkdownText)
          .where((text) => text.trim().isNotEmpty)
          .join('\n');
    }
    if (value is Map) {
      const priorityKeys = [
        'markdown',
        'text',
        'content',
        'body',
        'summary',
        'title',
        'description',
      ];
      final parts = <String>[];

      for (final key in priorityKeys) {
        if (value.containsKey(key)) {
          final text = _extractMarkdownText(value[key]);
          if (text.trim().isNotEmpty) {
            parts.add(text.trim());
          }
        }
      }

      for (final entry in value.entries) {
        if (priorityKeys.contains(entry.key)) continue;
        final text = _extractMarkdownText(entry.value);
        if (text.trim().isNotEmpty) {
          parts.add(text.trim());
        }
      }

      return parts.join('\n\n');
    }
    return value.toString();
  }

  String _segmentText(dynamic segment) {
    if (segment is String) return segment;
    if (segment is Map) {
      final speaker = segment['speaker']?.toString() ?? '';
      final text =
          segment['text']?.toString() ?? segment['content']?.toString() ?? '';
      if (speaker.isNotEmpty && text.isNotEmpty) return '$speaker: $text';
      return text.isNotEmpty ? text : segment.toString();
    }
    return segment.toString();
  }

  Widget _markdown(BuildContext context, String text) {
    final colors = context.colors;
    final base = context.typo.bodyMedium.copyWith(
      color: colors.textPrimary,
      height: 1.5,
    );

    return MarkdownBody(
      data: text,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: base,
        strong: base.copyWith(fontWeight: FontWeight.w700),
        em: base.copyWith(fontStyle: FontStyle.italic),
        h1: context.typo.headline2.copyWith(color: colors.textPrimary),
        h2: context.typo.headline3.copyWith(color: colors.textPrimary),
        h3: context.typo.headline4.copyWith(color: colors.textPrimary),
        listBullet: base,
        blockquote: base.copyWith(color: colors.textSecondary),
        code: context.typo.bodySmall.copyWith(color: colors.primary),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AppNeumoSurface(
        circle: true,
        soft: true,
        width: size,
        height: size,
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

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Shows a check instead of the chevron — used by the category picker.
  final bool selected;

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
            Icon(icon, size: Design.spacing.iconSmall, color: colors.primary),
            SizedBox(width: Design.spacing.sm),
            Expanded(
              child: Text(
                label,
                style: context.typo.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              selected ? Design.icons.check : Design.icons.rightArrow,
              size: Design.spacing.iconSmall,
              color: selected ? colors.primary : colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
