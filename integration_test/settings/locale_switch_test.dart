// integration_test/settings/locale_switch_test.dart
//
// Reproduces the report: "when changing language English -> Burmese in
// settings, it's stuck showing loading".
//
// Exercises the REAL popup path (language menu -> tap "မြန်မာ", which fires
// PopupMenuButton.onSelected -> SettingController.changeLocale) and watches
// route + visible pages + the global loading flag + popup barriers for ~32s,
// then switches back to English.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/auth/controllers/auth.controller.dart';
import 'package:rexone_mobile/modules/home/pages/home.page.dart';
import 'package:rexone_mobile/modules/setting/controllers/setting.controller.dart';
import 'package:rexone_mobile/modules/setting/pages/setting.page.dart';
import 'package:rexone_mobile/modules/splash/pages/splash.page.dart';
import 'package:rexone_mobile/routes/routes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('locale switch EN -> MY does not wedge the app', (tester) async {
    app.main();

    // ---- session bootstrap (same as the ask repro test) ----
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
    await tester.pump(const Duration(seconds: 2));
    debugPrint(
      '🏁 booted route=${Get.currentRoute} '
      'loading=${AppLoading.isGlobalLoading.value}',
    );

    // ---- go to settings (what the profile avatar does) ----
    Get.toNamed(AppRoutes.settings);
    await _waitUntil(
      tester,
      () => find.byType(SettingPage).evaluate().isNotEmpty,
      seconds: 15,
    );
    await tester.pump(const Duration(seconds: 2));
    debugPrint(
      '🏁 settings open route=${Get.currentRoute} '
      'loading=${AppLoading.isGlobalLoading.value}',
    );

    // ---- open the language menu (the real user path) ----
    final menu = find.byType(PopupMenuButton<String>);
    debugPrint('🏁 popup buttons=${menu.evaluate().length}');
    if (menu.evaluate().isNotEmpty) {
      // Physical tap first; if it doesn't open, use the button's own
      // showButtonMenu() — same route/onSelected machinery the user triggers.
      await tester.tap(
        find.byIcon(Design.icons.downArrow).first,
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 900));
      if (find.byType(PopupMenuItem<String>).evaluate().isEmpty) {
        debugPrint('🏁 tap did not open menu — showButtonMenu()');
        tester.state<PopupMenuButtonState<String>>(menu.first).showButtonMenu();
        await tester.pump(const Duration(milliseconds: 900));
      }
      debugPrint(
        '🏁 menu items=${find.byType(PopupMenuItem<String>).evaluate().length} '
        'barriers=${find.byType(ModalBarrier).evaluate().length} '
        'loading=${AppLoading.isGlobalLoading.value}',
      );

      final myItem = find.widgetWithText(PopupMenuItem<String>, 'မြန်မာ');
      debugPrint(
        '🏁 burmese item=${myItem.evaluate().length} locale=${Get.locale}',
      );
      if (myItem.evaluate().isNotEmpty) {
        await tester.tap(myItem.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 700));
        debugPrint(
          '🏁 item tapped locale=${Get.locale} '
          'barriers=${find.byType(ModalBarrier).evaluate().length} '
          'loading=${AppLoading.isGlobalLoading.value}',
        );
        if (Get.locale == null || Get.locale!.languageCode != 'my') {
          debugPrint('🏁 item tap did not switch — fallback direct call');
          Get.find<SettingController>().changeLocale('my_MM');
        }
      } else {
        debugPrint('🏁 no burmese item — fallback direct changeLocale');
        Get.find<SettingController>().changeLocale('my_MM');
      }
    } else {
      Get.find<SettingController>().changeLocale('my_MM');
    }

    // ---- watch for 12s, then out to ~32s ----
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
      debugPrint(
        '🏁 t+${i + 1}s route=${Get.currentRoute} '
        'splash=${find.byType(SplashPage).evaluate().length} '
        'settings=${find.byType(SettingPage).evaluate().length} '
        'home=${find.byType(HomePage).evaluate().length} '
        'barriers=${find.byType(ModalBarrier).evaluate().length} '
        'loading=${AppLoading.isGlobalLoading.value}',
      );
    }
    await tester.pump(const Duration(seconds: 20));
    debugPrint(
      '🏁 t+32s loading=${AppLoading.isGlobalLoading.value} '
      'route=${Get.currentRoute}',
    );

    // ---- switch back via the same popup path ----
    debugPrint('🏁 switching back to en_US');
    final menu2 = find.byType(PopupMenuButton<String>);
    if (menu2.evaluate().isNotEmpty) {
      tester.state<PopupMenuButtonState<String>>(menu2.first).showButtonMenu();
      await tester.pump(const Duration(milliseconds: 900));
      final enItem = find.widgetWithText(PopupMenuItem<String>, 'English');
      if (enItem.evaluate().isNotEmpty) {
        await tester.tap(enItem.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 700));
      } else {
        Get.find<SettingController>().changeLocale('en_US');
      }
    } else {
      Get.find<SettingController>().changeLocale('en_US');
    }
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    debugPrint(
      '🏁 after back locale=${Get.locale} route=${Get.currentRoute} '
      'loading=${AppLoading.isGlobalLoading.value} '
      'settings=${find.byType(SettingPage).evaluate().length}',
    );
    debugPrint('🏁 LOCALE_SWITCH_DONE');
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
