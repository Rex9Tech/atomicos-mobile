// lib/modules/home/pages/widgets/atom_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/routes.dart';

import '../../data/models/atom.model.dart';

/// Summary card for one atom — shared by Home and Search results.
///
/// Classic raised soft-UI: same clay as the page, extruded by the dual
/// diagonal shadow pair. The source tag sits in a soft inset well.
class AtomCard extends StatelessWidget {
  const AtomCard({super.key, required this.atom});

  final AtomModel atom;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = _shortDate(atom.createdAt);
    final duration = _compactDuration(atom.durationSecs);
    // Cards have a fixed size budget: the body is capped to a few lines'
    // worth of text (first paragraph, collapsed, word-safe ellipsis).
    final summary = _cardSummary(atom);

    return GestureDetector(
      onTap: () => AppRoutes.toAtomDetail(atomId: atom.id),
      behavior: HitTestBehavior.opaque,
      child: AppNeumoSurface(
        radius: Design.spacing.radiusXLarge,
        padding: EdgeInsets.all(Design.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SourceChip(source: atom.source),
                const Spacer(),
                _statusBadge(atom.status),
              ],
            ),
            SizedBox(height: Design.spacing.md),
            Text(
              atom.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.typo.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            if (summary.isNotEmpty) ...[
              SizedBox(height: Design.spacing.xs),
              MarkdownBody(
                data: summary,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet(
                  p: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                  strong: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                  em: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                  blockquote: context.typo.bodySmall.copyWith(
                    color: colors.textMuted,
                    height: 1.4,
                  ),
                  code: context.typo.caption.copyWith(color: colors.primary),
                ),
              ),
            ],
            if (date.isNotEmpty || duration.isNotEmpty) ...[
              SizedBox(height: Design.spacing.sm),
              Row(
                children: [
                  if (date.isNotEmpty) ...[
                    Icon(
                      Design.icons.calendar,
                      size: 13,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: context.typo.caption.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                  if (date.isNotEmpty && duration.isNotEmpty)
                    Text(
                      ' · ',
                      style: context.typo.caption.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  if (duration.isNotEmpty) ...[
                    Icon(Design.icons.clock, size: 13, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: context.typo.caption.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Recessed source label — the "GOOGLE MEET" well from the soft-UI mock.
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppNeumoSurface(
      depth: ENeumoDepth.inset,
      soft: true,
      radius: 999,
      padding: EdgeInsets.symmetric(
        horizontal: Design.spacing.sm,
        vertical: Design.spacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _sourceIcon(source),
            size: Design.spacing.iconSmall,
            color: colors.textSecondary,
          ),
          SizedBox(width: Design.spacing.xs),
          Text(
            source.toUpperCase(),
            style: context.typo.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _sourceIcon(String source) {
  switch (source.toLowerCase()) {
    case 'url':
      return Design.icons.link;
    case 'share':
      return Design.icons.shareIos;
    case 'asset':
      return Design.icons.attachment;
    case 'meeting':
      return Design.icons.mic;
    default:
      return Design.icons.note;
  }
}

String _shortDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}

String _compactDuration(int? secs) {
  if (secs == null || secs <= 0) return '';
  final h = secs ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return '${secs}s';
}

Widget _statusBadge(String status) {
  final variant = switch (status.toLowerCase()) {
    'completed' => EBadgeVariant.success,
    'processing' => EBadgeVariant.warning,
    'failed' => EBadgeVariant.error,
    _ => EBadgeVariant.info,
  };
  final label = status.isEmpty ? 'draft' : status;
  return AppBadge(
    text: label[0].toUpperCase() + label.substring(1).toLowerCase(),
    type: variant,
  );
}

String _summaryMarkdown(AtomModel atom) {
  if (atom.summaryBlocks.isNotEmpty) {
    final text = _extractMarkdownText(atom.summaryBlocks.first).trim();
    if (text.isNotEmpty) return text;
  }
  return atom.note?.trim() ?? '';
}

/// Card size budget: max characters of body text kept on an atom card.
const int _maxSummaryChars = 150;

/// Collapses whitespace/newlines and truncates at a word boundary so home
/// and search cards stay a predictable height regardless of how long the
/// atom's summary or note is.
String _cardSummary(AtomModel atom) {
  final raw = _summaryMarkdown(atom).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (raw.length <= _maxSummaryChars) return raw;

  final cut = raw.substring(0, _maxSummaryChars);
  final lastSpace = cut.lastIndexOf(' ');
  final body = lastSpace >= _maxSummaryChars ~/ 2
      ? cut.substring(0, lastSpace)
      : cut;
  return '${body.trimRight()}…';
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
