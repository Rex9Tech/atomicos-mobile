// lib/design/components/app_card.dart
import 'package:flutter/material.dart';

import '../design.dart';

/// Neumorphic (soft-UI) surface: the same tone as the page, lifted by a dual
/// shadow — light from the top-left, shade to the bottom-right. Pass
/// [borderColor] only where a hairline is genuinely needed.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? Design.spacing.radiusMedium;

    final content = Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.neumo,
        // Convex surface wash (skip for custom tone fills).
        gradient: backgroundColor == null ? colors.neumoGradient : null,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: colors.neumoShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
