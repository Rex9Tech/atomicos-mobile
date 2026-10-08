// test/design/app_dialog_color_test.dart
//
// Regression guard for the "Enable notifications" dialog: ordinary confirm
// actions render in Atomic Green (or the caller's explicit color) — never
// the destructive red — and explicit action colors actually survive to the
// rendered button (AppButton's text variant used to drop them, so every
// dialog action fell back to a single default style).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/locales.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('text AppButtons render the explicit color', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(
              type: EButtonType.text,
              text: 'Enable',
              color: const Color(0xFF22C55E),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final style = tester.widget<TextButton>(find.byType(TextButton)).style;
    expect(
      style?.foregroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF22C55E),
    );
  });

  testWidgets('AppDialog.confirm passes the confirm color to its action', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final result = AppDialog.confirm(
      context: context,
      title: 'Enable notifications',
      message: 'M',
      confirmLabel: 'Enable',
      confirmColor: const Color(0xFF22C55E),
    );
    await tester.pumpAndSettle();

    final confirm = find.widgetWithText(TextButton, 'Enable');
    expect(confirm, findsOneWidget);
    final style = tester.widget<TextButton>(confirm).style;
    expect(
      style?.foregroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF22C55E),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });
}
