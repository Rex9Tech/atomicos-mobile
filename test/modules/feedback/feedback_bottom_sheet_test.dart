// test/modules/feedback/feedback_bottom_sheet_test.dart
//
// Regression guard for "the feedback sheet closes but the keyboard stays".
// Closing the Share Your Feedback sheet must drop the IME along with the
// field, not leave it floating over the Settings screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/locales.dart';
import 'package:rexone_mobile/modules/feedback/components/feedback_bottom_sheet.dart';
import 'package:rexone_mobile/modules/feedback/services/feedback.service.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<FeedbackService>(FakeFeedbackService());
  });

  tearDown(Get.reset);

  testWidgets('closing the sheet dismisses the keyboard', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: Design.theme.light,
        home: const Scaffold(),
      ),
    );

    FeedbackBottomSheet.show();
    await tester.pumpAndSettle();

    // Focus the feedback field — the keyboard comes up.
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    // Close via the X — the keyboard must go with the sheet.
    await tester.tap(find.byIcon(Design.icons.close));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });
}
