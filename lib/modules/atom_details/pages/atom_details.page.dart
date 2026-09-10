import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/modules/home/home.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(context),
          SizedBox(height: Design.spacing.lg),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final atom = controller.atom.value;
              if (atom == null || controller.hasError.value) {
                return _buildError(context);
              }
              return _buildContent(context, atom);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        GestureDetector(
          onTap: Get.back,
          child: Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Design.icons.backArrow,
              size: Design.spacing.iconSmall,
              color: colors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: Design.spacing.sm),
        Text(
          AppLocales.atom.title.tr,
          style: context.typo.labelMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AtomModel atom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAtomHeader(context, atom),
        SizedBox(height: Design.spacing.lg),
        _buildTabs(context),
        SizedBox(height: Design.spacing.lg),
        Expanded(child: _buildTabBody(context, atom)),
      ],
    );
  }

  Widget _buildAtomHeader(BuildContext context, AtomModel atom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                atom.title,
                style: context.typo.headline3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: Design.spacing.sm),
            _iconAction(context, Design.icons.clipboard, () => _copyAtom(atom)),
          ],
        ),
        SizedBox(height: Design.spacing.xs),
        Row(
          children: [
            _badge(context, atom.source.toUpperCase()),
            SizedBox(width: Design.spacing.sm),
            _badge(context, atom.status),
          ],
        ),
      ],
    );
  }

  Widget _badge(BuildContext context, String label) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Design.spacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.typo.caption.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final colors = context.colors;

    return Obx(
      () => Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final selected = controller.activeTab.value == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == _tabs.length - 1 ? 0 : Design.spacing.sm,
              ),
              child: GestureDetector(
                onTap: () => controller.selectTab(index),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: Design.spacing.sm),
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? colors.primary : colors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.typo.labelMedium.copyWith(
                      color: selected ? colors.background : colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBody(BuildContext context, AtomModel atom) {
    return Obx(() {
      switch (controller.activeTab.value) {
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
    if (atom.summaryBlocks.isEmpty) {
      return _emptyState(context, AppLocales.atom.noSummary.tr);
    }
    return _scrollableCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: atom.summaryBlocks.map((block) {
          return Padding(
            padding: EdgeInsets.only(bottom: Design.spacing.sm),
            child: _markdown(context, _blockText(block)),
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
    return _scrollableCard(
      context,
      _markdown(context, note),
    );
  }

  Widget _buildAssets(BuildContext context, AtomModel atom) {
    if (atom.assets.isEmpty) {
      return _emptyState(context, AppLocales.atom.noAssets.tr);
    }
    return _scrollableCard(
      context,
      Column(
        children: atom.assets.map((asset) {
          return GestureDetector(
            onTap: () => _openAsset(asset),
            child: Padding(
              padding: EdgeInsets.only(bottom: Design.spacing.sm),
              child: Row(
                children: [
                  Icon(
                    Design.icons.attachment,
                    size: Design.spacing.iconSmall,
                    color: context.colors.textSecondary,
                  ),
                  SizedBox(width: Design.spacing.sm),
                  Expanded(
                    child: Text(
                      asset.name,
                      style: context.typo.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    (asset.format.isNotEmpty ? asset.format : asset.type)
                        .toUpperCase(),
                    style: context.typo.caption.copyWith(
                      color: context.colors.textSecondary,
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
        }).toList(),
      ),
    );
  }

  Widget _iconAction(BuildContext context, IconData icon, VoidCallback onTap) {
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
          size: Design.spacing.iconSmall,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _copyAtom(AtomModel atom) async {
    final parts = <String>[
      atom.title,
      if ((atom.note ?? '').trim().isNotEmpty) atom.note!.trim(),
      for (final b in atom.summaryBlocks)
        if (b is Map) (b['text'] ?? b['content'] ?? '').toString().trim(),
    ].where((e) => e.isNotEmpty);

    await Clipboard.setData(ClipboardData(text: parts.join('\n\n')));
    AppSnackbar.success(AppLocales.atom.copiedToClipboard.tr);
  }

  Future<void> _openAsset(AtomAssetModel asset) async {
    final uri = Uri.tryParse(asset.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _scrollableCard(BuildContext context, Widget child) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Design.spacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
          border: Border.all(color: context.colors.border),
        ),
        child: child,
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Center(
      child: Text(
        message,
        style: context.typo.bodySmall.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocales.atom.loadFailed.tr,
            style: context.typo.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: Design.spacing.md),
          GestureDetector(
            onTap: controller.loadAtom,
            child: Text(
              AppLocales.atom.retry.tr,
              style: context.typo.bodyMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _blockText(dynamic block) {
    if (block is String) return block;
    if (block is Map) {
      return (block['text'] ?? block['content'] ?? block['title'] ?? '')
          .toString();
    }
    return block.toString();
  }

  String _segmentText(dynamic segment) {
    if (segment is String) return segment;
    if (segment is Map) {
      final speaker = segment['speaker']?.toString() ?? '';
      final text = segment['text']?.toString() ?? segment['content']?.toString() ?? '';
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
