import 'package:flutter/material.dart';

import '../design.dart';

enum EAppToneCardTone {
  neutral,
  primary,
  info,
  warning,
  success,
  error,
}

class AppToneCard extends StatelessWidget {
  const AppToneCard({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.leadingIcon,
    this.trailing,
    this.footer,
    this.onTap,
    this.padding,
    this.tone = EAppToneCardTone.neutral,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final IconData? leadingIcon;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EAppToneCardTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _accentColor(context);

    return AppCard(
      onTap: onTap,
      padding: padding ?? EdgeInsets.all(Design.spacing.md),
      borderRadius: Design.spacing.radiusLarge,
      backgroundColor: colors.surface,
      borderColor: tone == EAppToneCardTone.neutral
          ? colors.border
          : accent.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null || trailing != null)
            Row(
              children: [
                if (eyebrow != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Design.spacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      eyebrow!,
                      style: context.typo.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (eyebrow != null && trailing != null)
                  SizedBox(width: Design.spacing.sm),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          if (eyebrow != null || trailing != null)
            SizedBox(height: Design.spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingIcon != null) ...[
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    leadingIcon,
                    color: accent,
                    size: Design.spacing.iconMedium,
                  ),
                ),
                SizedBox(width: Design.spacing.md),
              ],
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
                    if (subtitle != null) ...[
                      SizedBox(height: Design.spacing.xs),
                      Text(
                        subtitle!,
                        style: context.typo.bodySmall.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            SizedBox(height: Design.spacing.md),
            footer!,
          ],
        ],
      ),
    );
  }

  Color _accentColor(BuildContext context) {
    final colors = context.colors;
    switch (tone) {
      case EAppToneCardTone.primary:
        return colors.primary;
      case EAppToneCardTone.info:
        return colors.info;
      case EAppToneCardTone.warning:
        return colors.warning;
      case EAppToneCardTone.success:
        return colors.success;
      case EAppToneCardTone.error:
        return colors.error;
      case EAppToneCardTone.neutral:
        return colors.textSecondary;
    }
  }
}
