// lib/design/components/app_glass_card.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../design.dart';

/// Frosted-glass surface: translucent fill + backdrop blur + hairline border +
/// soft diffuse shadow. The morphism building block used across the design.
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.blur = 18,
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
        color: color ?? context.colors.glass,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: borderColor ?? context.colors.glassBorder),
        boxShadow: shadow ?? context.colors.softShadow,
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: onTap == null
            ? content
            : GestureDetector(onTap: onTap, child: content),
      ),
    );
  }
}
