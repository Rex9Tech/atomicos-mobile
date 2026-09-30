// integration_test/media/audio_upload_test.dart
//
// Audio upload end to end: builds a tiny WAV inside the app, uploads it
// through the real MediaService (POST /v1/media/upload), creates an atom
// from the asset, then cleans both up. Guards the Sept-2026 route regression
// ('/assets/upload' → 404 "Not Found" on every upload).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/atom_create/atom_create.dart';
import 'package:rexone_mobile/modules/auth/auth.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uploading an audio file creates an asset and an atom',
      (tester) async {
    app.main();

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
      await auth.signIn();
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(HomePage).evaluate().isNotEmpty) break;
      }
    }
    expect(find.byType(HomePage), findsOneWidget, reason: 'home available');

    // 1) Build a tiny WAV in the app's temp dir.
    final wav = _tinyWav();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/e2e-audio-upload.wav');
    file.writeAsBytesSync(wav);
    debugPrint('UPTEST file=${file.path} bytes=${wav.length}');

    // 2) Upload through the real service.
    final media = Get.find<MediaService>();
    final upload = await media.uploadImage(
      filePath: file.path,
      filename: 'e2e-audio-upload.wav',
      folder: 'atoms',
      showLoading: false,
    );
    debugPrint(
      'UPTEST upload success=${upload.success} code=${upload.statusCode} '
      'id=${upload.data?.id} error=${upload.error}',
    );
    expect(
      upload.success,
      isTrue,
      reason: 'audio upload must succeed (404 = route regression)',
    );
    final assetId = upload.data?.id ?? '';
    expect(assetId, isNotEmpty);

    // 3) Create an atom around the asset (the create-screen flow).
    final created = await Get.find<AtomCreateService>().createFromAsset(
      AtomFromAssetRequest(assetId: assetId),
    );
    debugPrint('UPTEST atom success=${created.success} id=${created.data?.id}');
    expect(created.success, isTrue);
    final atomId = created.data?.id ?? '';
    expect(atomId, isNotEmpty);

    // 4) Clean up: remove the probe atom + its asset from prod.
    final atomDeleted = await Get.find<HomeService>().deleteAtom(atomId);
    final api = Get.find<ApiService>();
    final assetDeleted = await api.delete(
      '${ServerRoutes.assets}/$assetId',
      showLoading: false,
    );
    debugPrint(
      'UPTEST cleanup atom=$atomDeleted assetCode=${assetDeleted.statusCode}',
    );

    Get.closeAllSnackbars();
    await tester.pump(const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}

/// 8-bit PCM WAV: 'RIFF' header + a short square tone.
List<int> _tinyWav() {
  const sampleRate = 8000;
  const frames = 1600; // 0.2s
  final samples =
      List<int>.generate(frames, (i) => i % 40 < 20 ? 64 : 192);
  final bytes = <int>[];
  void ascii(String s) => bytes.addAll(s.codeUnits);
  void u32(int v) => bytes.addAll(
    [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF],
  );
  void u16(int v) => bytes.addAll([v & 0xFF, (v >> 8) & 0xFF]);
  ascii('RIFF');
  u32(36 + samples.length);
  ascii('WAVE');
  ascii('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(sampleRate);
  u32(sampleRate);
  u16(1);
  u16(8); // 8-bit
  ascii('data');
  u32(samples.length);
  bytes.addAll(samples);
  return bytes;
}
