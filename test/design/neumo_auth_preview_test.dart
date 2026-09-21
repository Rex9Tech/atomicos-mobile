// TEMP preview harness — renders the auth/login components to goldens for
// visual review. Not part of the permanent suite; delete after review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_translations.dart';

void main() {
  testWidgets('auth surfaces preview (light + dark)', (tester) async {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en');
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final themes = <String, ThemeData>{
      'light': Design.theme.light,
      'dark': Design.theme.dark,
    };

    for (final entry in themes.entries) {
      final name = entry.key;
      await tester.pumpWidget(
        MaterialApp(
          theme: entry.value,
          home: Builder(
            builder: (context) {
              final colors = context.colors;
              final pinController = PinInputController();
              return Scaffold(
                backgroundColor: colors.neumo,
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: context.typo.headline1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'One workspace for every meeting and note.',
                          textAlign: TextAlign.center,
                          style: context.typo.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        AppButton(type: EButtonType.google, onPressed: () {}),
                        const SizedBox(height: 24),
                        AppInputField(
                          label: 'Email',
                          hint: 'you@example.com',
                          helper: 'We will send a sign-in code',
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 20),
                        AppInputField(
                          label: 'Note',
                          hint: 'Write something',
                          error: 'This one shows the error state',
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 20),
                        AppPasswordField(pinController: pinController),
                        const SizedBox(height: 28),
                        AppButton(text: 'Continue', onPressed: () {}),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/auth_surfaces_$name.png'),
      );
    }
  });
}
