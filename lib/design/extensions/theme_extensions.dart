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
  /// does the lifting (theme switch keeps a slightly raised dark surface).
  Color get neumo => isDark
      ? _context.theme.colorScheme.surface
      : _context.theme.scaffoldBackgroundColor;

  /// Raised soft-UI surface: light falls from the top-left, shade to the
  /// bottom-right. Tuned stronger by tester request — the dual shadow should
  /// read clearly as raised relief on both themes.
  List<BoxShadow> get neumoShadow => isDark
      ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(-6, -6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 50,
            offset: const Offset(6, 6),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.white.withValues(alpha: 1.0),
            blurRadius: 16,
            offset: const Offset(-6, -6),
          ),
          // Wider blur keeps the shade a diffuse falloff rather than a
          // visible gray band (reviewed via golden previews).
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(7, 7),
          ),
        ];

  /// Softer dual shadow for small, tight components (chips, buttons).
  List<BoxShadow> get neumoShadowSoft => isDark
      ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.14),
            blurRadius: 9,
            offset: const Offset(-4, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(4, 4),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.white.withValues(alpha: 1.0),
            blurRadius: 9,
            offset: const Offset(-4, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 16,
            offset: const Offset(4, 4),
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
