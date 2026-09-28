// integration_test/create/upload_visual_test.dart
//
// Visual check for the Create Atom -> Import -> Upload stage: holds the page
// in light theme, then dark, while host-side screencaps capture the layout
// (box centering, chip rows, soft-UI surfaces). Debug builds white-screen on
// this device; run with `flutter drive --profile`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/atom_create/controllers/atom_create.controller.dart';
import 'package:rexone_mobile/modules/auth/controllers/auth.controller.dart';
import 'package:rexone_mobile/modules/home/pages/home.page.dart';
import 'package:rexone_mobile/modules/setting/controllers/setting.controller.dart';
import 'package:rexone_mobile/routes/routes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('create-atom upload stage visual check', (tester) async {
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

    // Light theme for the first hold.
    Get.find<SettingController>().setDarkMode(false);
    await tester.pump(const Duration(milliseconds: 600));

    AppRoutes.toAtomCreate();
    await _waitUntil(
      tester,
      () => Get.currentRoute == AppRoutes.atomCreate,
      seconds: 15,
    );
    await tester.pump(const Duration(milliseconds: 800));
    Get.find<AtomCreateController>().selectMode('upload');
    debugPrint('📸 UPLOAD_OPEN');
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    debugPrint('📸 UPLOAD_DARK_NOW');
    Get.find<SettingController>().setDarkMode(true);
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    Get.find<SettingController>().setDarkMode(false);
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('📸 UPLOAD_VISUAL_DONE');
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
