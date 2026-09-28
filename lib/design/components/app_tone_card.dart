import 'package:flutter/material.dart';

import '../design.dart';

enum EAppToneCardTone { neutral, primary, info, warning, success, error }

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
    // Keep the text clear of the trailing widget, which is centred on the
    // right edge no matter how tall the row gets.
    final trailingGutter = trailing == null
        ? 0.0
        : Design.spacing.iconMedium + Design.spacing.sm;

    return AppCard(
      onTap: onTap,
      padding: padding ?? EdgeInsets.all(Design.spacing.md),
      borderRadius: Design.spacing.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
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
            SizedBox(height: Design.spacing.md),
          ],
          Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leadingIcon != null) ...[
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          Design.spacing.radiusLarge,
                        ),
                      ),
                      child: Icon(
                        leadingIcon,
                        color: accent,
                        size: Design.spacing.iconLarge,
                      ),
                    ),
                    SizedBox(width: Design.spacing.md),
                  ],
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: trailingGutter),
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
                  ),
                ],
              ),
              if (trailing != null)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                ),
            ],
          ),
          if (footer != null) ...[SizedBox(height: Design.spacing.md), footer!],
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
