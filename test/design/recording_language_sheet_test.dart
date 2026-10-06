// test/design/recording_language_sheet_test.dart
//
// The recording-language chooser: the user's pick must stick (applied to
// SpeechService + persisted), and dismissing must keep the current selection.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_translations.dart';
import 'package:rexone_mobile/services/services.dart';

import '../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<StorageService>(FakeStorageService());
    Get.put<SpeechService>(FakeSpeechService());
  });

  tearDown(Get.reset);

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: Design.theme.light,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('picking English applies and persists it', (tester) async {
    await pumpHost(tester);

    final speech = Get.find<SpeechService>();
    final storage = Get.find<StorageService>();
    String? applied;
    showRecordingLanguageSheet().then((value) => applied = value);
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('မြန်မာ'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(applied, 'en-US');
    expect(speech.recordingLanguage.value, 'en-US');
    expect(storage.getRecordingLanguage(), 'en-US');
  });

  testWidgets('picking မြန်မာ applies and persists it', (tester) async {
    await pumpHost(tester);

    final speech = Get.find<SpeechService>();
    final storage = Get.find<StorageService>();
    String? applied;
    showRecordingLanguageSheet().then((value) => applied = value);
    await tester.pumpAndSettle();

    await tester.tap(find.text('မြန်မာ'));
    await tester.pumpAndSettle();

    expect(applied, 'my-MM');
    expect(speech.recordingLanguage.value, 'my-MM');
    expect(storage.getRecordingLanguage(), 'my-MM');
  });

  testWidgets('dismissing keeps the current language', (tester) async {
    await pumpHost(tester);

    final speech = Get.find<SpeechService>();
    speech.recordingLanguage.value = 'my-MM';

    String? applied;
    showRecordingLanguageSheet().then((value) => applied = value);
    await tester.pumpAndSettle();

    // Dismiss via the barrier (a tap well above the sheet).
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(applied, 'my-MM');
    expect(speech.recordingLanguage.value, 'my-MM');
  });
}
