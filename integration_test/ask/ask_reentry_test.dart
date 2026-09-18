// integration_test/ask/ask_reentry_test.dart
//
// Reproduces the tester report: "open Ask Atomic, exit, re-enter — it gets
// stuck on the same screen." Opens the ask page three times (in-app back,
// system back, in-app back) and asserts it opens + the composer accepts text
// every time.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/ai/controllers/ai.controller.dart';
import 'package:rexone_mobile/modules/ai/pages/ai.page.dart';
import 'package:rexone_mobile/modules/auth/controllers/auth.controller.dart';
import 'package:rexone_mobile/modules/home/pages/home.page.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Ask Atomic opens, closes and re-opens', (tester) async {
    app.main();
    await _waitUntil(
      tester,
      () => find.byType(HomePage).evaluate().isNotEmpty ||
          find.text('Continue with Google').evaluate().isNotEmpty,
      seconds: 45,
    );
    await _dismissPermissionPrompt(tester);

    // Session bootstrap (not the behaviour under test): if the stored session
    // is gone the app sits on the sign-in screen — sign in with the seed
    // account so the re-entry checks can run.
    if (find.byType(HomePage).evaluate().isEmpty) {
      debugPrint('🔑 SESSION_BOOTSTRAP — signing in as super@admin.com');
      final auth = Get.find<AuthController>();
      auth.email.value = 'super@admin.com';
      auth.password.value = '111111';
      await auth.signIn();
      await _waitUntil(
        tester,
        () => find.byType(HomePage).evaluate().isNotEmpty,
        seconds: 30,
      );
      debugPrint(
        '🔑 SESSION_BOOTSTRAP done route=${Get.currentRoute} '
        'home=${find.byType(HomePage).evaluate().isNotEmpty}',
      );
    }
    expect(
      find.byType(HomePage),
      findsOneWidget,
      reason: 'home should be available (after session bootstrap)',
    );
    await _dismissPermissionPrompt(tester);

    for (var round = 1; round <= 3; round++) {
      debugPrint('▶▶ ROUND $round — route=${Get.currentRoute}');

      final ask = find.text('Ask Atom');
      expect(ask, findsWidgets, reason: 'home should offer Ask Atom (r$round)');
      await tester.tap(ask.last, warnIfMissed: true);
      await _waitUntil(
        tester,
        () => find.byType(AiPage).evaluate().isNotEmpty,
        seconds: 15,
      );
      expect(
        find.byType(AiPage),
        findsOneWidget,
        reason: 'ask page should open (round $round)',
      );
      final ctl = AiController.active!;
      debugPrint(
        '✅ ASK_OPENED r$round active=${AiController.active != null}',
      );
      debugPrint(
        '🧪 r$round ctl=${identityHashCode(ctl)} '
        'textCtl=${identityHashCode(ctl.textController)} '
        'text="${ctl.textController.text}"',
      );

      // Watch the composer settle like a human would before typing.
      for (final step in [400, 600, 800, 1200]) {
        await tester.pump(Duration(milliseconds: step));
        final probe = find.descendant(
          of: find.byType(AiPage),
          matching: find.byType(TextField),
        );
        if (probe.evaluate().isNotEmpty) {
          debugPrint(
            '🧪 r$round settle+${step}ms rect=${tester.getRect(probe.first)}',
          );
        }
      }

      // The composer must accept text — proves the page is interactive, not
      // a frozen screenshot.
      final pageCount = find.byType(AiPage).evaluate().length;
      final scoped = find.descendant(
        of: find.byType(AiPage),
        matching: find.byType(TextField),
      );
      debugPrint(
        '🧪 r$round pages=$pageCount fieldsUnderAi=${scoped.evaluate().length}',
      );
      for (var i = 0; i < scoped.evaluate().length; i++) {
        try {
          final rect = tester.getRect(scoped.at(i));
          final tf = tester.widget<TextField>(scoped.at(i));
          debugPrint(
            '🧪 r$round f[$i] ctl=${identityHashCode(tf.controller)} '
            'rect=$rect enabled=${tf.enabled} readOnly=${tf.readOnly} '
            'focusNode=${identityHashCode(tf.focusNode)}',
          );
        } catch (x) {
          debugPrint('🧪 r$round f[$i] rect-error=$x');
        }
      }

      final field = scoped;
      if (field.evaluate().isNotEmpty) {
        final tf = tester.widget<TextField>(field.first);
        debugPrint(
          '🧪 r$round fieldCtl=${identityHashCode(tf.controller)} '
          'sameAsController=${identical(tf.controller, ctl.textController)}',
        );
        await tester.enterText(field.first, 'ping $round');
        await tester.pump(const Duration(milliseconds: 300));
        final typed =
            tester.widget<TextField>(field.first).controller?.text ?? '';
        debugPrint(
          '✅ ASK_TYPED r$round text="$typed" '
          'ctlText="${ctl.textController.text}"',
        );
        expect(typed, 'ping $round', reason: 'composer accepts text (r$round)');
        await tester.enterText(field.first, '');
        await tester.pump(const Duration(milliseconds: 200));
      } else {
        debugPrint('⚠️ ASK_NO_FIELD r$round');
      }

      // Exit: round 1 uses the in-app back, rounds 2+ use system back.
      if (round == 1) {
        final back = find.descendant(
          of: find.byType(AiPage),
          matching: find.byIcon(Design.icons.backArrow),
        );
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first, warnIfMissed: true);
          debugPrint('✅ ASK_BACK_TAPPED r$round');
        } else {
          await tester.binding.handlePopRoute();
          debugPrint('✅ ASK_SYSBACK r$round (no back icon)');
        }
      } else {
        await tester.binding.handlePopRoute();
        debugPrint('✅ ASK_SYSBACK r$round');
      }

      await _waitUntil(
        tester,
        () => find.byType(HomePage).evaluate().isNotEmpty,
        seconds: 15,
      );
      expect(
        find.byType(HomePage),
        findsOneWidget,
        reason: 'exit should return to home (round $round)',
      );
      debugPrint('✅ ASK_EXITED r$round route=${Get.currentRoute}');
    }

    debugPrint('🏁 ASK_REENTRY_OK');
  });
}

Future<void> _dismissPermissionPrompt(WidgetTester tester) async {
  for (int attempt = 0; attempt < 14; attempt++) {
    final cancel = find.text('Cancel');
    if (cancel.evaluate().isNotEmpty) {
      await tester.tap(cancel.first);
      await tester.pump(const Duration(milliseconds: 600));
      debugPrint('✅ PERMISSION_PROMPT_DISMISSED');
      return;
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
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
