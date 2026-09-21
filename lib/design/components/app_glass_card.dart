// lib/design/components/app_glass_card.dart
import 'package:flutter/material.dart';

import '../design.dart';

/// Neumorphic raised surface — formerly the frosted-glass card. Keeps the same
/// API (radius, padding, onTap, color, borderColor, shadow) so every screen
/// that used it picks up the soft-UI treatment in one place.
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.blur = 18, // kept for API compatibility; unused in soft UI
    this.onTap,
    this.color,
    this.borderColor,
    this.shadow,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final double blur;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? Design.spacing.radiusXLarge;

    final content = Container(
      width: width,
      padding: padding ?? EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: color ?? context.colors.neumo,
        // Convex surface wash (skip for custom tone fills).
        gradient: color == null ? context.colors.neumoGradient : null,
        borderRadius: BorderRadius.circular(r),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: shadow ?? context.colors.neumoShadow,
      ),
      child: child,
    );

    return onTap == null
        ? content
        : GestureDetector(onTap: onTap, child: content);
  }
}
