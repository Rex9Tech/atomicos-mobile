// test/modules/ai/ai_page_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_translations.dart';
import 'package:rexone_mobile/modules/ai/ai.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/services/permission.service.dart';
import 'package:rexone_mobile/services/speech.service.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<AiService>(FakeAiService());
    Get.put<SpeechService>(FakeSpeechService());
    Get.put<PermissionService>(FakePermissionService());
    Get.put<RecordingService>(FakeRecordingService());
    Get.put<HomeService>(FakeHomeService());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('chat header stays visible when scrolled to the last message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1125, 2436); // 375 x 812 @3x
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: Design.theme.light,
        home: const AiPage(),
      ),
    );
    await tester.pumpAndSettle();

    final controller = AiController.active!;
    controller.entryMode.value = 'ask';
    controller.askStage.value = 'prompt_result';
    controller.messages.assignAll([
      for (var i = 0; i < 14; i++)
        AiMessageModel(
          id: 'msg_$i',
          role: i.isEven ? 'user' : 'assistant',
          content:
              'Message $i — the quick brown fox jumps over the lazy dog and '
              'keeps running until the paragraph is comfortably long.',
          status: 'completed',
          createdAt: DateTime.now().toIso8601String(),
        ),
    ]);
    await tester.pumpAndSettle();

    // The header (clock = rooms button) is visible before scrolling.
    expect(
      tester.getTopLeft(find.byIcon(Design.icons.clock)).dy,
      lessThan(120),
    );

    // Scroll the conversation to the very end.
    controller.scrollController.jumpTo(
      controller.scrollController.position.maxScrollExtent,
    );
    await tester.pumpAndSettle();

    // Regression guard: the header used to scroll away with the messages.
    // It must stay pinned at the top of the chat.
    final headerY = tester.getTopLeft(find.byIcon(Design.icons.clock)).dy;
    expect(headerY, greaterThanOrEqualTo(0));
    expect(headerY, lessThan(120));
  });
}
