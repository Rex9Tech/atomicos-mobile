// lib/design/components/app_glass_card.dart
import 'package:flutter/material.dart';

import '../design.dart';

/// Raised neumorphic surface — formerly the frosted-glass card.
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
    final colors = context.colors;
    // Custom color/shadow still count as raised soft-UI unless a hairline
    // border is supplied.
    final useNeumo = borderColor == null && shadow == null;

    final content = useNeumo
        ? AppNeumoSurface(
            width: width,
            radius: r,
            color: color,
            padding: padding ?? EdgeInsets.all(Design.spacing.lg),
            child: child,
          )
        : Container(
            width: width,
            padding: padding ?? EdgeInsets.all(Design.spacing.lg),
            decoration: BoxDecoration(
              color: color ?? colors.neumo,
              borderRadius: BorderRadius.circular(r),
              border: borderColor != null
                  ? Border.all(color: borderColor!)
                  : null,
              boxShadow: shadow ??
                  (borderColor == null ? colors.neumoShadow : null),
            ),
            child: child,
          );

    return onTap == null
        ? content
        : GestureDetector(onTap: onTap, child: content);
  }
}
