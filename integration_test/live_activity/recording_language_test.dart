// integration_test/live_activity/recording_language_test.dart
//
// Recording asks for the transcription language up front: open the recording
// sheet, pick မြန်မာ, and the live session must start pinned to my-MM.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/locales/app_locales.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/auth/auth.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/modules/live_activity/live_activity.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recording asks for the language and applies the pick', (
    tester,
  ) async {
    app.main();

    // Bootstrap a session (home page).
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(HomePage).evaluate().isNotEmpty) break;
      if (find.byType(TextField).evaluate().isNotEmpty) break;
    }
    if (find.byType(HomePage).evaluate().isEmpty) {
      debugPrint('KEY SESSION_BOOTSTRAP — signing in as super@admin.com');
      final auth = Get.find<AuthController>();
      auth.email.value = 'super@admin.com';
      auth.password.value = '111111';
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          await auth.signIn();
        } catch (error) {
          debugPrint('RLOK signin attempt $attempt threw: $error');
        }
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (find.byType(HomePage).evaluate().isNotEmpty) break;
        }
        if (find.byType(HomePage).evaluate().isNotEmpty) break;
      }
    }
    expect(find.byType(HomePage), findsOneWidget, reason: 'home available');

    // Open the recording sheet — the language picker greets it.
    AppRoutes.toLiveActivity();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('မြန်မာ').evaluate().isNotEmpty) break;
    }
    expect(find.text('မြန်မာ'), findsWidgets, reason: 'language sheet shown');
    expect(find.text('English'), findsOneWidget);

    // The sheet sits above the page (its option renders last in the tree).
    await tester.tap(find.text('မြန်မာ').last);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(HomePage).evaluate().isNotEmpty) break;
    }

    final controller = Get.find<LiveActivityController>();
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (controller.isRecording.value) break;
    }

    final speech = Get.find<SpeechService>();
    debugPrint(
      'RLOK recording=${controller.isRecording.value} '
      'lang=${speech.activeRecordingLanguage}',
    );
    expect(speech.activeRecordingLanguage, 'my-MM');
    expect(controller.isRecording.value, isTrue, reason: 'recording started');

    // The live STT session should come up while recording.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (speech.isListening.value) break;
    }
    debugPrint('RLOK listening=${speech.isListening.value}');

    // End the session: uploads the capture and creates the atom.
    await controller.finishRecording();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    debugPrint('RLOK finished');

    // Best-effort cleanup: remove the throwaway "Live meeting" atom.
    try {
      final home = Get.find<HomeService>();
      final result = await home.getAtoms(limit: 5);
      for (final record in result.records) {
        if (record.title == AppLocales.recording.liveMeeting.tr) {
          await home.deleteAtom(record.id);
          debugPrint('RLOK cleanup deleted ${record.id}');
          break;
        }
      }
    } catch (error) {
      debugPrint('RLOK cleanup skipped: $error');
    }
    Get.closeAllSnackbars();
  });
}
