import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/modules/home/home.dart';

import '../controllers/atom_details.controller.dart';

class AtomDetailsPage extends GetView<AtomDetailsController> {
  const AtomDetailsPage({super.key});

  static const _tabs = ['Summary', 'Transcript', 'Note', 'Assets'];

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
          'Atom',
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
        Text(
          atom.title,
          style: context.typo.headline3.copyWith(fontWeight: FontWeight.w700),
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
      return _emptyState(context, 'No summary yet');
    }
    return _scrollableCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: atom.summaryBlocks.map((block) {
          return Padding(
            padding: EdgeInsets.only(bottom: Design.spacing.sm),
            child: Text(
              _blockText(block),
              style: context.typo.bodyMedium.copyWith(height: 1.4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTranscript(BuildContext context, AtomModel atom) {
    if (atom.transcriptSegments.isEmpty) {
      return _emptyState(context, 'No transcript yet');
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
      return _emptyState(context, 'No note');
    }
    return _scrollableCard(
      context,
      Text(
        note,
        style: context.typo.bodyMedium.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildAssets(BuildContext context, AtomModel atom) {
    if (atom.assets.isEmpty) {
      return _emptyState(context, 'No assets');
    }
    return _scrollableCard(
      context,
      Column(
        children: atom.assets.map((asset) {
          return Padding(
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
              ],
            ),
          );
        }).toList(),
      ),
    );
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
            "Couldn't load this atom",
            style: context.typo.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: Design.spacing.md),
          GestureDetector(
            onTap: controller.loadAtom,
            child: Text(
              'Retry',
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
}
