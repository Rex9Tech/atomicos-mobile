// lib/design/extensions/theme_extensions.dart
import 'package:flutter/material.dart';
import '../design.dart';

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
}

extension ThemeColors on BuildContext {
  AppThemeContextColors get colors => AppThemeContextColors(this);
}

class AppThemeContextColors {
  const AppThemeContextColors(this._context);
  final BuildContext _context;

  ColorScheme get colorScheme => _context.theme.colorScheme;

  Color get primary => _context.theme.colorScheme.primary;
  Color get secondary => _context.theme.colorScheme.secondary;
  Color get error => _context.theme.colorScheme.error;
  Color get background => _context.theme.scaffoldBackgroundColor;
  Color get surface => _context.theme.colorScheme.surface;
  Color get card =>
      _context.theme.cardTheme.color ?? _context.theme.colorScheme.surface;
  Color get divider => _context.theme.dividerColor;
  Color get border => _context.theme.colorScheme.outline;
  Color get textPrimary => _context.theme.colorScheme.onSurface;
  Color get textSecondary => _context.theme.colorScheme.onSurfaceVariant;
  Color get textMuted =>
      _context.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
  Color get textTertiary => textMuted;
  Color get onPrimary => _context.theme.colorScheme.onPrimary;
  Color get onError => _context.theme.colorScheme.onError;
  Color get onSecondary => _context.theme.colorScheme.onSecondary;
  Color get success => Design.colors.success;
  Color get onSuccess => Colors.white;
  Color get warning => Design.colors.warning;
  Color get onWarning => Colors.white;
  Color get info => Design.colors.info;
  Color get onInfo => Colors.white;

  // ===== GLASSMORPHISM (morphism design) =====
  bool get isDark => _context.theme.brightness == Brightness.dark;

  /// Frosted translucent surface fill.
  Color get glass =>
      isDark ? Design.colors.glass.card : Colors.white.withValues(alpha: 0.72);

  /// Stronger (more opaque) frosted fill for bars/sheets.
  Color get glassStrong => isDark
      ? Design.colors.glass.cardHover
      : Colors.white.withValues(alpha: 0.9);

  /// Hairline light border used on glass surfaces.
  Color get glassBorder => isDark
      ? Design.colors.glass.border
      : Colors.white.withValues(alpha: 0.85);

  // ===== NEUMORPHISM (soft UI) =====
  /// Neumorphic surface fill — the same tone as the page, so the dual shadow
  /// and gradient do the lifting (theme switch keeps a slightly raised dark
  /// surface).
  Color get neumo => isDark
      ? _context.theme.colorScheme.surface
      : _context.theme.scaffoldBackgroundColor;

  /// Convex soft-UI surface wash, mirroring flutter_neumorphic's convex
  /// shader: translucent dark at the bottom-right fading to a light wash
  /// toward the top-left (the light source). Draw it OVER [neumo].
  LinearGradient get neumoGradient => LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: isDark
        ? [
            Colors.black.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0.09),
          ]
        : [
            Colors.black.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.55),
          ],
    stops: const [0, 0.78],
  );

  /// Raised soft-UI surface: light falls from the top-left, shade to the
  /// bottom-right — tight, defined dual shadows in the flutter_neumorphic
  /// proportions (their blur scales with depth, ~1:2 offset:blur), softened
  /// one notch after tester feedback ("a little bit too much").
  List<BoxShadow> get neumoShadow => isDark
      ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.16),
            blurRadius: 13,
            offset: const Offset(-4, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.58),
            blurRadius: 17,
            offset: const Offset(4, 4),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.95),
            blurRadius: 11,
            offset: const Offset(-4, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.11),
            blurRadius: 14,
            offset: const Offset(4, 4),
          ),
        ];

  /// Softer dual shadow for small, tight components (chips, buttons).
  List<BoxShadow> get neumoShadowSoft => isDark
      ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 9,
            offset: const Offset(-3, -3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.52),
            blurRadius: 12,
            offset: const Offset(3, 3),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.95),
            blurRadius: 8,
            offset: const Offset(-3, -3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 10,
            offset: const Offset(3, 3),
          ),
        ];

  /// Soft diffuse shadow for floating glass surfaces.
  List<BoxShadow> get softShadow => Design.colors.shadows.md;
}

extension ThemeTypography on BuildContext {
  AppThemeContextTypography get typo => AppThemeContextTypography(this);
}

class AppThemeContextTypography {
  const AppThemeContextTypography(this._context);
  final BuildContext _context;

  // Headlines
  TextStyle get headline1 => Design.typo.headline1.copyWith(
    color: _context.theme.colorScheme.onSurface,
  );

  TextStyle get headline2 => Design.typo.headline2.copyWith(
    color: _context.theme.colorScheme.onSurface,
  );

  TextStyle get headline3 => Design.typo.headline3.copyWith(
    color: _context.theme.colorScheme.onSurface,
  );

  TextStyle get headline4 => Design.typo.headline4.copyWith(
    color: _context.theme.colorScheme.onSurface,
  );

  // Body
  TextStyle get bodyLarge => Design.typo.bodyLarge.copyWith(
    color: _context.theme.colorScheme.onSurface,
  );

  TextStyle get bodyMedium => Design.typo.bodyMedium.copyWith(
    color: _context.theme.colorScheme.onSurfaceVariant,
  );

  TextStyle get bodySmall => Design.typo.bodySmall.copyWith(
    color: _context.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
  );

  // Labels
  TextStyle get labelLarge => Design.typo.labelLarge.copyWith(
    color: _context.theme.colorScheme.onSurface,
  );

  TextStyle get labelMedium => Design.typo.labelMedium.copyWith(
    color: _context.theme.colorScheme.onSurfaceVariant,
  );

  // Buttons
  TextStyle get button =>
      Design.typo.button.copyWith(color: _context.theme.colorScheme.onSurface);

  // Caption & Helper
  TextStyle get caption => Design.typo.caption.copyWith(
    color: _context.theme.colorScheme.onSurfaceVariant,
  );

  TextStyle get helper => Design.typo.helper.copyWith(
    color: _context.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
  );

  TextStyle get link => Design.typo.link;
}
