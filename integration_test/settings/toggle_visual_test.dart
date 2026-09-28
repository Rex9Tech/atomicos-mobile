// integration_test/settings/toggle_visual_test.dart
//
// Visual check for the settings theme toggle: opens Settings in light theme,
// holds for a screenshot window, flips to dark, holds again. Host-side
// screencaps are taken while the test pumps (drive --profile renders on this
// device; debug builds white-screen).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/auth/controllers/auth.controller.dart';
import 'package:rexone_mobile/modules/home/pages/home.page.dart';
import 'package:rexone_mobile/modules/setting/controllers/setting.controller.dart';
import 'package:rexone_mobile/modules/setting/pages/setting.page.dart';
import 'package:rexone_mobile/routes/routes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('settings toggle stays visible in light and dark', (tester) async {
    app.main();

    await _waitUntil(
      tester,
      () =>
          find.byType(HomePage).evaluate().isNotEmpty ||
          find.text('Continue with Google').evaluate().isNotEmpty,
      seconds: 45,
    );
    if (find.byType(HomePage).evaluate().isEmpty) {
      debugPrint('🔑 SESSION_BOOTSTRAP');
      final auth = Get.find<AuthController>();
      auth.email.value = 'super@admin.com';
      auth.password.value = '111111';
      await auth.signIn();
      await _waitUntil(
        tester,
        () => find.byType(HomePage).evaluate().isNotEmpty,
        seconds: 30,
      );
    }

    // Deterministic: start in LIGHT theme.
    Get.find<SettingController>().setDarkMode(false);
    await tester.pump(const Duration(milliseconds: 800));

    Get.toNamed(AppRoutes.settings);
    await _waitUntil(
      tester,
      () => find.byType(SettingPage).evaluate().isNotEmpty,
      seconds: 15,
    );
    await tester.pump(const Duration(seconds: 2));
    debugPrint('📸 LIGHT_READY');
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    debugPrint('📸 DARK_NOW');
    Get.find<SettingController>().toggleTheme();
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Restore light theme so the phone is left in the user's state.
    Get.find<SettingController>().setDarkMode(false);
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('📸 TOGGLE_VISUAL_DONE');
  });
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  int seconds = 20,
  int pumpMs = 250,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await tester.pump(Duration(milliseconds: pumpMs));
  }
}
