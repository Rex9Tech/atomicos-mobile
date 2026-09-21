// test/modules/ai/ai_details_tabs_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_translations.dart';
import 'package:rexone_mobile/modules/ai/ai.dart';
import 'package:rexone_mobile/modules/home/data/models/atom.model.dart';
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

  AtomModel atom({
    List summaryBlocks = const [],
    List transcriptSegments = const [],
    String? note,
  }) {
    return AtomModel(
      id: 'a1',
      title: 'My note',
      source: 'note',
      status: 'completed',
      note: note,
      summaryBlocks: summaryBlocks,
      transcriptSegments: transcriptSegments,
      createdAt: '',
      updatedAt: '',
    );
  }

  Future<void> pumpCanvas(WidgetTester tester) async {
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
  }

  testWidgets('a note atom hides the Summary and Transcript tabs', (
    tester,
  ) async {
    await pumpCanvas(tester);

    final controller = AiController.active!;
    controller.entryMode.value = 'details';
    controller.contextAtom.value = atom(note: 'Hello from a note');
    await tester.pumpAndSettle();

    Finder tab(String label) =>
        find.descendant(of: find.byType(TabBar), matching: find.text(label));

    // Tester request: 'hide the summary and transcripts' for note atoms.
    expect(tab('Summary'), findsNothing);
    expect(tab('Transcripts'), findsNothing);
    expect(tab('Note'), findsOneWidget);
    expect(tab('Assets'), findsOneWidget);
  });

  testWidgets('an atom with a real summary and transcript keeps its tabs', (
    tester,
  ) async {
    await pumpCanvas(tester);

    final controller = AiController.active!;
    controller.entryMode.value = 'details';
    controller.contextAtom.value = atom(
      summaryBlocks: [
        {'type': 'summary', 'text': 'Key points from the meeting.'},
      ],
      transcriptSegments: [
        {'text': 'Speaker one opened the meeting.'},
      ],
    );
    await tester.pumpAndSettle();

    Finder tab(String label) =>
        find.descendant(of: find.byType(TabBar), matching: find.text(label));

    expect(tab('Summary'), findsOneWidget);
    expect(tab('Transcripts'), findsOneWidget);
    expect(tab('Note'), findsOneWidget);
    expect(tab('Assets'), findsOneWidget);
  });
}
