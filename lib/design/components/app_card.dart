// lib/design/components/app_card.dart
import 'package:flutter/material.dart';

import '../design.dart';

/// Raised neumorphic surface: lifted by dual outer shadows.
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
    // Custom fills (tone cards) still lift with the raised pair — only a
    // hairline border opts out of soft-UI depth.
    final useNeumo = borderColor == null;

    final content = useNeumo
        ? AppNeumoSurface(
            radius: radius,
            color: backgroundColor,
            padding: padding ?? EdgeInsets.all(Design.spacing.lg),
            margin: margin,
            child: child,
          )
        : Container(
            margin: margin,
            padding: padding ?? EdgeInsets.all(Design.spacing.lg),
            decoration: BoxDecoration(
              color: backgroundColor ?? colors.neumo,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor!),
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
