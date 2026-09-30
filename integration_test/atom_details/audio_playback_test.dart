// integration_test/atom_details/audio_playback_test.dart
//
// Verifies the atom-details audio fix: the source recording must actually
// PLAY. Regression it guards: just_audio_background requires every audio
// source to carry a MediaItem tag — the screen used a plain `setUrl()`, so
// playback died with "type 'Null' is not a subtype of type 'MediaItem'" and
// the position stayed at 00:00.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/atom_details/atom_details.dart';
import 'package:rexone_mobile/modules/auth/auth.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/routes/routes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('atom details recording plays (position advances)', (
    tester,
  ) async {
    app.main();

    // Boot past splash.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(HomePage).evaluate().isNotEmpty) break;
      if (find.byType(TextField).evaluate().isNotEmpty) break; // auth screen
    }

    // Session bootstrap (not the behaviour under test): after a fresh install
    // the app sits on the sign-in screen — use the seed admin account.
    if (find.byType(HomePage).evaluate().isEmpty) {
      debugPrint('🔑 SESSION_BOOTSTRAP — signing in as super@admin.com');
      final auth = Get.find<AuthController>();
      auth.email.value = 'super@admin.com';
      auth.password.value = '111111';
      await auth.signIn();
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(HomePage).evaluate().isNotEmpty) break;
      }
    }
    expect(
      find.byType(HomePage),
      findsOneWidget,
      reason: 'home available (after session bootstrap)',
    );

    // Candidate atoms: prefer ones with a duration (recordings); try a few
    // until one has a resolvable source-audio url.
    final service = Get.find<HomeService>();
    final res = await service.getAtoms(limit: 30);
    expect(res.records, isNotEmpty, reason: 'need atoms on the account');
    var candidates =
        res.records.where((a) => (a.durationSecs ?? 0) > 0).toList();
    if (candidates.isEmpty) candidates = res.records.toList();

    AtomDetailsController? controller;
    for (final candidate in candidates.take(5)) {
      debugPrint('🎧 trying atom "${candidate.title}" (${candidate.id})');
      AppRoutes.toAtomDetail(atomId: candidate.id);
      AtomDetailsController? found;
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (Get.isRegistered<AtomDetailsController>()) {
          final c = Get.find<AtomDetailsController>();
          if (c.atomId.value == candidate.id) {
            found = c;
            if (c.audioUrl.value != null) break;
            if (!c.isLoading.value) break; // loaded, but no audio source
          }
        }
      }
      if (found != null && found.audioUrl.value != null) {
        controller = found;
        break;
      }
      if (Get.currentRoute != AppRoutes.home) {
        Get.back();
        await tester.pump(const Duration(milliseconds: 600));
      }
    }
    expect(
      controller,
      isNotNull,
      reason: 'found an atom with a playable recording',
    );

    // Play and watch the clock move — the actual regression check.
    await controller!.togglePlayback();
    var advanced = false;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (controller.position.value > Duration.zero) {
        advanced = true;
        break;
      }
    }
    debugPrint(
      '🎧 result: isPlaying=${controller.isPlaying.value} '
      'position=${controller.position.value}',
    );
    expect(controller.isPlaying.value, isTrue, reason: 'player is playing');
    expect(advanced, isTrue, reason: 'position advanced past 00:00');

    await controller.togglePlayback(); // pause before finishing
    await Future<void>.delayed(const Duration(seconds: 2));
  });
}
