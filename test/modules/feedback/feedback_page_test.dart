// test/modules/feedback/feedback_page_test.dart
//
// The feedback form is a full screen now (was a bottom sheet whose keyboard
// handling was unreliable: closing it could leave the IME floating over the
// next screen). Guards: the route renders the form, submitting works, and
// leaving the form takes the keyboard with it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/locales.dart';
import 'package:rexone_mobile/modules/feedback/controllers/feedback.controller.dart';
import 'package:rexone_mobile/modules/feedback/pages/feedback.page.dart';
import 'package:rexone_mobile/modules/feedback/services/feedback.service.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFeedbackService fakeService;

  setUp(() {
    Get.testMode = true;
    fakeService = FakeFeedbackService();
    Get.put<FeedbackService>(fakeService);
  });

  tearDown(Get.reset);

  Future<void> pumpFeedbackRoute(WidgetTester tester) async {
    // Mirror the physical test phone (1280x2772 @2.75 ≈ 465x1008 logical) —
    // a too-narrow viewport makes test-font metrics overflow the slider row.
    tester.view.physicalSize = const Size(1280, 2772);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: Design.theme.light,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold(body: Text('base'))),
          GetPage(
            name: '/feedback',
            page: () => const FeedbackPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut<FeedbackController>(() => FeedbackController());
            }),
          ),
        ],
      ),
    );

    Get.toNamed('/feedback');
    await tester.pumpAndSettle();
  }

  testWidgets('submitting leaves the form and drops the keyboard', (
    tester,
  ) async {
    await pumpFeedbackRoute(tester);

    expect(find.byType(FeedbackPage), findsOneWidget);
    expect(find.text(AppLocales.feedback.submit.tr), findsOneWidget);
    expect(Get.isRegistered<FeedbackController>(), isTrue);

    // Focus the text area — the keyboard comes up.
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(find.byType(TextField).first, 'Love the app');
    await tester.pump();

    await tester.ensureVisible(find.text(AppLocales.feedback.submit.tr));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppLocales.feedback.submit.tr));
    await tester.pumpAndSettle();

    expect(fakeService.lastSubmittedData, isNotNull);
    expect(
      fakeService.lastSubmittedData![FeedbackKeys.content],
      equals('Love the app'),
    );

    // Back on the base screen with the keyboard gone. The route's binding
    // owns the controller, so a popped route also disposes it.
    expect(find.byType(FeedbackPage), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
