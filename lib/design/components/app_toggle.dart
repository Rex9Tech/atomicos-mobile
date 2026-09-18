// lib/design/components/app_toggle.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../design.dart';

/// Brand toggle switch (theme-aware, neumorphism friendly).
///
/// Every state resolves from centralized tokens so the control is visible on
/// both light and dark surfaces:
/// - selected: primary track, white knob, no ring.
/// - unselected: muted track with a soft ring, white knob.
///
/// Note: flutter resolves `Switch.trackColor` (the WidgetStateProperty) with
/// priority over `activeTrackColor`/`inactiveTrackColor` in EVERY state — a
/// single `WidgetStateProperty.all(...)` would paint the selected track with
/// the unselected color too (previous bug: border-gray track + default
/// outline-gray knob on a white card = an invisible "blank" switch in light
/// theme).
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.trackColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  /// Overrides the unselected track color (fill and ring). Defaults to a
  /// muted token so the switch never blends into light surfaces.
  final Color? trackColor;

  static bool get isIOS => GetPlatform.isIOS;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return osToggle(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? colors.primary,
      inactiveTrackColor:
          trackColor ?? colors.textMuted.withValues(alpha: 0.35),
      inactiveOutlineColor:
          trackColor ?? colors.textMuted.withValues(alpha: 0.7),
    );
  }

  static Widget osToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
    Color? inactiveTrackColor,
    Color? inactiveOutlineColor,
  }) {
    if (isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor ?? CupertinoColors.systemBlue,
        inactiveTrackColor: inactiveTrackColor ?? CupertinoColors.systemGrey4,
      );
    }
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? activeColor
            : inactiveTrackColor,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : inactiveOutlineColor,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
