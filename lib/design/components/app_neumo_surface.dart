// lib/design/components/app_neumo_surface.dart
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design.dart';

/// Depth direction of a soft-UI surface.
enum ENeumoDepth {
  /// Pushed out of the page — lifted by outer shadows.
  raised,

  /// Pressed into the page — a well, lit from inside its own edges.
  inset,
}

/// Soft-UI surface that supports both raised and genuinely *recessed* depth.
///
/// Flutter's [BoxDecoration.boxShadow] only paints outside the shape, so an
/// inset well is impossible with decoration alone. [ENeumoDepth.inset] clips to
/// the shape and paints blurred shadow rings inward instead, which is what
/// gives the pressed look on inputs, tracks, and search fields.
class AppNeumoSurface extends StatelessWidget {
  const AppNeumoSurface({
    super.key,
    required this.child,
    this.depth = ENeumoDepth.raised,
    this.radius,
    this.circle = false,
    this.padding,
    this.margin,
    this.color,
    this.width,
    this.height,
    this.soft = false,
  });

  final Widget child;
  final ENeumoDepth depth;

  /// Corner radius; ignored when [circle] is true. Defaults to `radiusLarge`.
  final double? radius;

  /// Paints a perfect circle — use for icon buttons and avatars.
  final bool circle;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Surface fill; defaults to the raised neumo tone.
  final Color? color;

  final double? width;
  final double? height;

  /// Uses the lighter shadow pair, for chips and compact controls.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = color ?? (depth == ENeumoDepth.inset ? colors.background : colors.neumo);

    final content = Padding(
      padding: padding ?? EdgeInsets.all(Design.spacing.lg),
      child: child,
    );

    if (depth == ENeumoDepth.raised) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: fill,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle
              ? null
              : BorderRadius.circular(radius ?? Design.spacing.radiusLarge),
          boxShadow: soft ? colors.neumoShadowSoft : colors.neumoShadow,
        ),
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: fill,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle
            ? null
            : BorderRadius.circular(radius ?? Design.spacing.radiusLarge),
      ),
      foregroundDecoration: _InsetShadowDecoration(
        shadows: soft ? colors.neumoInsetShadowSoft : colors.neumoInsetShadow,
        circle: circle,
        radius: radius ?? Design.spacing.radiusLarge,
      ),
      child: content,
    );
  }
}

/// Paints blurred shadow rings *inside* the shape to fake an inset well.
@immutable
class _InsetShadowDecoration extends Decoration {
  const _InsetShadowDecoration({
    required this.shadows,
    required this.circle,
    required this.radius,
  });

  final List<BoxShadow> shadows;
  final bool circle;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _InsetShadowPainter(this);

  @override
  bool operator ==(Object other) =>
      other is _InsetShadowDecoration &&
      other.circle == circle &&
      other.radius == radius &&
      listEquals(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(circle, radius, Object.hashAll(shadows));
}

class _InsetShadowPainter extends BoxPainter {
  _InsetShadowPainter(this.decoration);

  final _InsetShadowDecoration decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;

    final rect = offset & size;
    final rrect = decoration.circle
        ? RRect.fromRectAndRadius(
            rect,
            Radius.circular(size.shortestSide / 2),
          )
        : RRect.fromRectAndRadius(
            rect,
            Radius.circular(decoration.radius),
          );

    canvas.save();
    canvas.clipRRect(rrect);

    // A ring is drawn per shadow: everything outside the (offset, shrunken)
    // shape, blurred. Clipped to the shape, only the inward bleed survives.
    final bleed = Path()..addRect(rect.inflate(size.longestSide));

    for (final shadow in decoration.shadows) {
      final hole = rrect.shift(shadow.offset).deflate(shadow.spreadRadius);
      final ring = Path.combine(
        PathOperation.difference,
        bleed,
        Path()..addRRect(hole),
      );

      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = ui.MaskFilter.blur(
          BlurStyle.normal,
          shadow.blurRadius / 2,
        );

      canvas.drawPath(ring, paint);
    }

    canvas.restore();
  }
}
