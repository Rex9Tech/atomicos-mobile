// lib/design/elements/app_colors.dart
import 'package:flutter/material.dart';

/// RexOne Design System Colors — Unified with Rex9 Design System.
/// Provides pure brand, semantic, day (light), night (dark), and glassmorphic tokens.
class AppColors {
  const AppColors();

  // ===== BRAND (AtomicOS Green Palette) =====
  Color get primary => const Color(0xFF22C55E);
  Color get primaryLight => const Color(0xFF4ADE80);
  Color get primaryDark => const Color(0xFF15803D);
  Color get secondary => const Color(0xFF34D399);
  Color get accent => const Color(0xFF166534);

  // ===== NEON GLOW COLORS =====
  Color get glowWhite => const Color(0xFFF0FDF4);
  Color get glowRuby => const Color(0xFF14532D);

  // ===== SEMANTIC (Unified across Light & Dark) =====
  Color get success => const Color(0xFF10B981);
  Color get warning => const Color(0xFFF59E0B);
  Color get error => const Color(0xFFEF4444);
  Color get info => const Color(0xFF38BDF8);

  // ===== DAY THEME (Light Mode) =====
  AppDayColors get day => const AppDayColors();

  // ===== NIGHT THEME (Dark Mode - AtomicOS Deep Forest) =====
  AppNightColors get night => const AppNightColors();

  // ===== GLASSMORPHISM =====
  AppGlassColors get glass => const AppGlassColors();

  // ===== GRADIENTS & SHADOWS =====
  GradientColors get gradient => const GradientColors();
  Shadows get shadows => const Shadows();
}

class AppDayColors {
  const AppDayColors();

  Color get background => const Color(0xFFFAFAF8);
  Color get surface => const Color(0xFFFFFFFF);
  Color get card => const Color(0xFFF5F5F3);
  Color get border => const Color(0xFFE5E7EB);
  Color get divider => const Color(0xFFF3F4F6);
  Color get textPrimary => const Color(0xFF111827);
  Color get textSecondary => const Color(0xFF4B5563);
  Color get textMuted => const Color(0xFF9CA3AF);
}

class AppNightColors {
  const AppNightColors();

  Color get background => const Color(0xFF08130D);
  Color get surface => const Color(0xFF0F1D14);
  Color get card => const Color(0xFF13261A);
  Color get border => const Color(0xFF23412E);
  Color get divider => const Color(0xFF193222);
  Color get textPrimary => const Color(0xFFFFFFFF);
  Color get textSecondary => const Color(0xFFD7E8DC);
  Color get textMuted => const Color(0xFF98B5A0);
}

class AppGlassColors {
  const AppGlassColors();

  Color get nav => const Color(0xBF08130D);
  Color get card => const Color(0x61112518);
  Color get cardHover => const Color(0x8C163222);
  Color get form => const Color(0xA60D1E14);
  Color get project => const Color(0x8C09150F);
  Color get border => const Color(0x3822C55E);
  Color get borderHover => const Color(0x8C22C55E);
  Color get tag => const Color(0xA622C55E);
  Color get tagBg => const Color(0x1422C55E);
}

class GradientColors {
  const GradientColors();
  final AppColors _colors = const AppColors();

  LinearGradient get primary => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_colors.primary, _colors.secondary],
  );

  LinearGradient get success => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_colors.success, const Color(0xFF34D399)],
  );

  LinearGradient get error => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_colors.error, const Color(0xFFF87171)],
  );
}

class Shadows {
  const Shadows();

  List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];

  List<BoxShadow> get neon => const [
    BoxShadow(
      color: Color(0xFF22C55E),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0xFF15803D),
      blurRadius: 25,
    ),
  ];

  List<BoxShadow> get neonLg => const [
    BoxShadow(
      color: Color(0xFF22C55E),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0xFF15803D),
      blurRadius: 25,
    ),
    BoxShadow(
      color: Color(0xFF14532D),
      blurRadius: 50,
    ),
  ];

  List<BoxShadow> get glassCard => const [
    BoxShadow(
      color: Color(0x5922C55E),
      blurRadius: 30,
      offset: Offset(0, 6),
    ),
  ];

  List<BoxShadow> get glassHover => const [
    BoxShadow(
      color: Color(0x7322C55E),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];
}
