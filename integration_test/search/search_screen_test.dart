// integration_test/search/search_screen_test.dart
//
// Verifies the Home search bar routes to the dedicated search screen and that
// the screen filters atoms + shows the "no result" state.
//
// MIUI blocks `adb shell input` injection, so UI interaction is driven from
// inside the app process via integration_test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_locales.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/home/pages/home.page.dart';
import 'package:rexone_mobile/modules/home/pages/widgets/atom_card.dart';
import 'package:rexone_mobile/modules/search/pages/search.page.dart';

import '../data/users.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('home search bar opens the dedicated search screen', (
    tester,
  ) async {
    app.main();

    // Boot: the device keeps a signed-in session, but fall back to signing in
    // with the repo's test account if the session was lost.
    await _waitUntil(
      tester,
      () =>
          find.byType(HomePage).evaluate().isNotEmpty ||
          find.byType(TextField).evaluate().isNotEmpty,
      seconds: 40,
    );
    if (find.byType(HomePage).evaluate().isEmpty) {
      await _signIn(tester);
    }
    expect(
      find.byType(HomePage),
      findsOneWidget,
      reason: 'home should be visible before searching',
    );

    // The app prompts for notification permission shortly after Home mounts.
    // Dismiss it so the modal barrier can't sit between the test and the UI.
    await _dismissPermissionPrompt(tester);

    // 1. Tap the search bar (the hero-tagged pill on Home).
    final searchBar = find.byWidgetPredicate(
      (widget) => widget is Hero && widget.tag == kSearchBarHeroTag,
    );
    expect(
      searchBar,
      findsOneWidget,
      reason: 'home should render the search bar',
    );
    await tester.tap(searchBar, warnIfMissed: true);
    await _waitUntil(
      tester,
      () => find.byType(SearchPage).evaluate().isNotEmpty,
      seconds: 15,
    );
    expect(
      find.byType(SearchPage),
      findsOneWidget,
      reason: 'tapping the search bar should open the dedicated search screen',
    );
    debugPrint('✅ SEARCH_SCREEN_OPENED');

    // 2. A query with no matches shows the empty state.
    final field = find.descendant(
      of: find.byType(SearchPage),
      matching: find.byType(TextField),
    );
    // The field rides in on the hero flight; wait for it to land inside the
    // page before asserting.
    await _waitUntil(
      tester,
      () => field.evaluate().isNotEmpty,
      seconds: 10,
      pumpMs: 200,
    );
    expect(field, findsOneWidget, reason: 'search screen should have a field');
    await tester.enterText(field, 'zzzqqq-nothing-matches-this');
    await _waitUntil(
      tester,
      () =>
          find.text(AppLocales.search.emptyTitle.tr).evaluate().isNotEmpty ||
          find
              .descendant(
                of: find.byType(SearchPage),
                matching: find.byType(AtomCard),
              )
              .evaluate()
              .isNotEmpty,
      seconds: 25,
      pumpMs: 400,
    );
    expect(
      find.text(AppLocales.search.emptyTitle.tr),
      findsOneWidget,
      reason: 'a query with no matches should show the empty state',
    );
    debugPrint('✅ SEARCH_EMPTY_STATE');

    // 3. Clearing the query brings the recent atoms back.
    final clearButton = find.descendant(
      of: find.byType(SearchPage),
      matching: find.byIcon(Design.icons.close),
    );
    if (clearButton.evaluate().isNotEmpty) {
      await tester.tap(clearButton.first);
    } else {
      await tester.enterText(field, '');
    }
    await _waitUntil(
      tester,
      () =>
          find
              .descendant(
                of: find.byType(SearchPage),
                matching: find.byType(AtomCard),
              )
              .evaluate()
              .isNotEmpty,
      seconds: 30,
      pumpMs: 400,
    );
    expect(
      find.descendant(
        of: find.byType(SearchPage),
        matching: find.byType(AtomCard),
      ),
      findsWidgets,
      reason: 'clearing the query should list the recent atoms again',
    );
    debugPrint('✅ SEARCH_RECENTS_LISTED');

    // Hold the screen on device for a few seconds so it can be screenshotted
    // from outside the test process.
    debugPrint('⏳ HOLDING_SEARCH_SCREEN');
    await Future<void>.delayed(const Duration(seconds: 20));
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

Future<void> _signIn(WidgetTester tester) async {
  final email = find.byType(TextField);
  if (email.evaluate().isEmpty) return;
  await tester.enterText(email.first, TestUsers.existing.email);
  await tester.pump(const Duration(milliseconds: 400));

  final continueButton = find.text('Continue');
  if (continueButton.evaluate().isNotEmpty) {
    await tester.tap(continueButton.first);
  }
  await tester.pump(const Duration(seconds: 2));

  final pin = find.byType(EditableText);
  if (pin.evaluate().isNotEmpty) {
    await tester.enterText(pin.first, TestUsers.existing.password);
  }
  await _waitUntil(
    tester,
    () => find.byType(HomePage).evaluate().isNotEmpty,
    seconds: 25,
  );
}
