// lib/routes/keyboard_dismiss.observer.dart
import 'package:flutter/material.dart';

/// Hides the on-screen keyboard whenever navigation changes the screen.
///
/// The IME only goes away when the focused field gives up focus — screens
/// that pushed or popped routes while a field was focused used to leave the
/// keyboard floating over the next screen (tester report: "navigating away
/// does not dismiss the keyboard; it remains visible and appears stuck over
/// the next screen"). Unfocusing on every route transition keeps the
/// keyboard scoped to the screen that actually asked for it.
class KeyboardDismissObserver extends NavigatorObserver {
  KeyboardDismissObserver();

  void _dismiss() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismiss();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
    super.didRemove(route, previousRoute);
  }
}
