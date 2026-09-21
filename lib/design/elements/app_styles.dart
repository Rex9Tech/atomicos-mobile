// lib/design/elements/app_styles.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';

class AppStyles {
  const AppStyles();

  // ===== INPUT STYLES =====
  InputDecoration input({
    String? label,
    String? hint,
    String? error,
    String? helper,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final colors = Get.theme.colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      helperText: helper,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      // Neumo: the field's shell (see AppInputField) paints the same-tone
      // surface + soft shadow — the decoration itself stays borderless and
      // transparent so the shell shows through.
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        horizontal: Design.spacing.lg,
        vertical: Design.spacing.md + 2,
      ),
      labelStyle: Design.typo.labelMedium,
      hintStyle: Design.typo.helper,
      errorStyle: Design.typo.caption.copyWith(color: colors.error),
    );
  }

  // ===== BUTTON STYLES =====
  ButtonStyle get buttonPrimary => ElevatedButton.styleFrom(
    backgroundColor: Design.colors.primary,
    foregroundColor: Design.colors.glowWhite,
    minimumSize: Size(double.infinity, Design.spacing.buttonHeight),
    padding: EdgeInsets.symmetric(
      horizontal: Design.spacing.xl,
      vertical: Design.spacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
      side: BorderSide(color: Design.colors.glass.border, width: 1),
    ),
    textStyle: Design.typo.button.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
    elevation: 2,
    shadowColor: Design.colors.primary.withValues(alpha: 0.5),
  );

  ButtonStyle get buttonSecondary => OutlinedButton.styleFrom(
    foregroundColor: Design.colors.primary,
    minimumSize: Size(double.infinity, Design.spacing.buttonHeight),
    padding: EdgeInsets.symmetric(
      horizontal: Design.spacing.xl,
      vertical: Design.spacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
    ),
    side: BorderSide(color: Design.colors.primary),
    textStyle: Design.typo.button,
  );

  ButtonStyle get buttonText => TextButton.styleFrom(
    foregroundColor: Design.colors.primary,
    padding: EdgeInsets.symmetric(
      horizontal: Design.spacing.sm,
      vertical: Design.spacing.sm,
    ),
    textStyle: Design.typo.labelLarge,
  );

  // ===== CARD STYLES =====
  BoxDecoration get card => BoxDecoration(
    color: Design.theme.colors.card,
    borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
    boxShadow: Design.colors.shadows.sm,
  );

  BoxDecoration get cardElevated => BoxDecoration(
    color: Design.theme.colors.surface,
    borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
    boxShadow: Design.colors.shadows.md,
  );

  // ===== CONTAINER STYLES =====
  BoxDecoration get container => BoxDecoration(
    color: Design.theme.colors.surface,
    borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
    border: Border.all(color: Design.theme.colors.border),
  );

  BoxDecoration get containerBordered => BoxDecoration(
    color: Design.theme.colors.surface,
    borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
    border: Border.all(color: Design.colors.primary, width: 2),
  );

  // ===== DIALOG STYLES =====
  BoxDecoration get dialog => BoxDecoration(
    color: Design.theme.colors.surface,
    borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
    boxShadow: Design.colors.shadows.lg,
  );

  // ===== CHIP STYLES =====
  BoxDecoration get chip => BoxDecoration(
    color: Design.colors.primary.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
    border: Border.all(color: Design.colors.primary.withValues(alpha: 0.2)),
  );

  BoxDecoration get chipSuccess => BoxDecoration(
    color: Design.colors.success.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
    border: Border.all(color: Design.colors.success.withValues(alpha: 0.2)),
  );

  BoxDecoration get chipError => BoxDecoration(
    color: Design.colors.error.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
    border: Border.all(color: Design.colors.error.withValues(alpha: 0.2)),
  );
}
