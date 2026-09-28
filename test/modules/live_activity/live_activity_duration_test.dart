// test/modules/live_activity/live_activity_duration_test.dart
//
// Regression guards for the tester row "audio input — duration longer than the
// file": every duration that accompanies a finished recording must come from
// the CAPTURED FILE's real length — never the wall-clock timer, which runs
// longer than the audio whenever background chunks get dropped.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/ai/models/recording.model.dart';
import 'package:rexone_mobile/modules/ai/services/recording.service.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/modules/live_activity/live_activity.dart';
import 'package:rexone_mobile/services/media.service.dart';
import 'package:rexone_mobile/services/recording_session.service.dart';
import 'package:rexone_mobile/services/socket.service.dart';
import 'package:rexone_mobile/services/speech.service.dart';

import '../../mocks/test_services.dart';

/// Notification updates must not touch the foreground-service plugin.
class FakeRecordingSessionService extends RecordingSessionService {
  @override
  Future<void> start({required String title}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> markRunning(String elapsed) async {}

  @override
  Future<void> markPaused(String elapsed) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 16 kHz mono 16-bit PCM, exactly what SpeechService writes.
  final bytesPerSecond =
      AppConstants.speechSampleRate * AppConstants.speechNumChannels * 2;

  late Directory dir;

  setUp(() {
    Get.testMode = true;
    dir = Directory.systemTemp.createTempSync('lv_duration');

    final media = FakeMediaService();
    Get.put<SpeechService>(FakeSpeechService());
    Get.put<RecordingService>(FakeRecordingService());
    Get.put<MediaService>(media);
    Get.put<HomeService>(FakeHomeService());
    Get.put<RecordingSessionService>(FakeRecordingSessionService());
    Get.put<SocketService>(FakeSocketService());
  });

  tearDown(() {
    Get.reset();
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Stub WAV of `dataBytes` audio bytes (44-byte header + payload) — the
  /// length math only needs real bytes on disk.
  File writeWav(int dataBytes) {
    final file = File('${dir.path}/rec.wav');
    file.writeAsBytesSync(List<int>.filled(44 + dataBytes, 0));
    return file;
  }

  group('capturedAudioSeconds', () {
    test('measures the file, not the clock', () {
      final controller = LiveActivityController();
      final file = writeWav(bytesPerSecond * 4);

      expect(controller.capturedAudioSeconds(file.path), 4);
    });

    test('rounds partial seconds', () {
      final controller = LiveActivityController();
      final file = writeWav(bytesPerSecond * 3 + bytesPerSecond ~/ 2);

      expect(controller.capturedAudioSeconds(file.path), 4);
    });

    test('returns null when there is no usable capture', () {
      final controller = LiveActivityController();

      expect(controller.capturedAudioSeconds(null), isNull);
      expect(controller.capturedAudioSeconds(''), isNull);
      expect(
        controller.capturedAudioSeconds('${dir.path}/missing.wav'),
        isNull,
      );
      expect(controller.capturedAudioSeconds(writeWav(0).path), isNull);
    });
  });

  group('finishRecording', () {
    test('reports the captured length to the recording and the upload', () async {
      final speech = Get.find<SpeechService>() as FakeSpeechService;
      final recording = Get.find<RecordingService>() as FakeRecordingService;
      final media = Get.find<MediaService>() as FakeMediaService;

      // The file holds 7.5s of audio while the on-screen timer ran 11s
      // (background chunks were dropped) — everything must record 8.
      final file = writeWav(bytesPerSecond * 7 + bytesPerSecond ~/ 2);
      speech.captureResultPath = file.path;
      recording.finishResponse = ApiResponse.success(
        message: 'Recording finished',
        statusCode: 200,
        data: RecordingModel.fromJson(const {'atom_id': 'atom-1'}),
      );

      final controller = LiveActivityController();
      controller.recordingId.value = 'rec-1';
      controller.elapsedSeconds.value = 11;

      await controller.finishRecording();

      expect(recording.lastFinishDurationSecs, 8);
      expect(media.lastUploadedDurationSecs, 8);
      // The temp capture is cleaned up once it reaches the atom.
      expect(file.existsSync(), isFalse);
    });

    test('falls back to the timer only when nothing was captured', () async {
      final speech = Get.find<SpeechService>() as FakeSpeechService;
      final recording = Get.find<RecordingService>() as FakeRecordingService;
      final media = Get.find<MediaService>() as FakeMediaService;

      speech.captureResultPath = null;
      recording.finishResponse = ApiResponse.success(
        message: 'Recording finished',
        statusCode: 200,
        data: RecordingModel.fromJson(const {'atom_id': 'atom-1'}),
      );

      final controller = LiveActivityController();
      controller.recordingId.value = 'rec-2';
      controller.elapsedSeconds.value = 11;

      await controller.finishRecording();

      expect(recording.lastFinishDurationSecs, 11);
      expect(media.lastUploadedDurationSecs, isNull);
    });
  });
}
