// lib/design/components/app_snackbar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import '../design.dart';

/// Soft-UI toast used everywhere (including socket events).
///
/// Renders as a raised [AppNeumoSurface] — same clay + dual shadow as the rest
/// of the app — with a tinted leading icon for status. Flat Material/Cupertino
/// bars with hairline borders are intentionally not used.
class AppSnackbar {
  AppSnackbar._();

  static void error(
    String message, {
    dynamic e,
    StackTrace? stk,
    VoidCallback? onTap,
  }) {
    _logError(message, e, stk);
    _show(
      title: AppLocales.common.error.tr,
      message: message,
      accent: Design.colors.error,
      icon: Design.icons.error,
      onTap: onTap,
    );
  }

  static void success(String message, {VoidCallback? onTap}) {
    _show(
      title: AppLocales.common.success.tr,
      message: message,
      accent: Design.colors.success,
      icon: Design.icons.check,
      onTap: onTap,
    );
  }

  static void warning(String message, {VoidCallback? onTap}) {
    _show(
      title: AppLocales.common.warning.tr,
      message: message,
      accent: Design.colors.warning,
      icon: Design.icons.warning,
      onTap: onTap,
    );
  }

  static void info(String message, {VoidCallback? onTap}) {
    _show(
      title: AppLocales.common.info.tr,
      message: message,
      accent: Design.colors.primary,
      icon: Design.icons.info,
      onTap: onTap,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    final context = Get.context;
    if (context == null) return;

    Get.closeAllSnackbars();

    final colors = context.colors;
    final topInset = MediaQuery.paddingOf(context).top;

    void handleTap() {
      Get.closeAllSnackbars();
      onTap?.call();
    }

    // Transparent host so the raised neumo clay + shadows are the only chrome.
    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(
        Design.spacing.lg,
        topInset + Design.spacing.sm,
        Design.spacing.lg,
        0,
      ),
      duration: duration ?? Design.timers.snackbar,
      overlayBlur: 0,
      isDismissible: true,
      // Tap lives on the surface — GetX's snackbar onTap can miss custom
      // messageText hit tests when the host is transparent.
      messageText: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : handleTap,
        child: AppNeumoSurface(
          soft: true,
          radius: Design.spacing.radiusLarge,
          padding: EdgeInsets.symmetric(
            horizontal: Design.spacing.md,
            vertical: Design.spacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNeumoSurface(
                circle: true,
                soft: true,
                width: 36,
                height: 36,
                padding: EdgeInsets.zero,
                color: accent.withValues(alpha: 0.14),
                child:
                    Icon(icon, color: accent, size: Design.spacing.iconMedium),
              ),
              SizedBox(width: Design.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Design.typo.labelLarge.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: Design.spacing.xs),
                    Text(
                      message,
                      style: Design.typo.bodyMedium.copyWith(
                        color: colors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _logError(String message, dynamic e, StackTrace? stk) {
    if (Get.testMode) return;

    final buffer = StringBuffer();
    buffer.writeln(
      '═══════════════════════════════════════════════════════════',
    );
    buffer.writeln('❌ ERROR ===> $message');
    buffer.writeln(
      '───────────────────────────────────────────────────────────',
    );

    buffer.writeln('📦 Error ===> $e');
    buffer.writeln('📦 Type ===> ${e.runtimeType}');

    if (stk != null) {
      buffer.writeln(
        '───────────────────────────────────────────────────────────',
      );
      buffer.writeln('📚 Stack Trace:');
      buffer.writeln(stk.toString());
    }

    debugPrint(buffer.toString());
  }
}
