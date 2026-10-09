// test/routes/keyboard_dismiss_observer_test.dart
//
// Regression guard for "navigating away does not dismiss the keyboard".
// The IME must follow screen transitions: pushing or popping a route while
// a field is focused used to leave the keyboard floating over the next
// screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rexone_mobile/routes/routes.dart';

void main() {
  testWidgets('pushing a route dismisses the keyboard', (tester) async {
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [KeyboardDismissObserver()],
        home: const Scaffold(body: Center(child: TextField())),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('popping a route dismisses the keyboard', (tester) async {
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [KeyboardDismissObserver()],
        home: const Scaffold(),
      ),
    );

    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: TextField())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });
}
