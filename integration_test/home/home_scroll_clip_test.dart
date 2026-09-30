// integration_test/home/home_scroll_clip_test.dart
//
// Verifies the fix for the reported bug: scrolling the home list painted the
// cards OVER the search bar / header area (ListView had clipBehavior Clip.none
// so items leaving the viewport kept painting outside the list bounds).
//
// The test drags the list up, then holds the scrolled state for ~20s so an
// external `adb exec-out screencap` can capture the frame for visual review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/home/pages/home.page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home list scrolls without painting over the header', (
    tester,
  ) async {
    app.main();

    // Wait for the app to boot to Home (stored session → auto sign-in).
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(HomePage).evaluate().isNotEmpty) break;
    }
    expect(find.byType(HomePage), findsOneWidget);

    final listFinder = find.byType(ListView).first;

    // Guard: the list must clip its viewport (regression: Clip.none overlapped
    // the header/search bar while scrolling).
    final list = tester.widget<ListView>(listFinder);
    expect(list.clipBehavior, Clip.hardEdge);

    // Scroll up and hold the scrolled state for the external screenshot.
    await tester.drag(listFinder, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 700));
    await Future<void>.delayed(const Duration(seconds: 20));
  });
}
