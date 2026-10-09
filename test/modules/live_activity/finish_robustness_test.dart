// test/modules/live_activity/finish_robustness_test.dart
//
// Regression guards for "tapping the red End button does not stop the
// meeting / the user cannot exit": a stalled or throwing teardown step must
// never wedge finishRecording. Every teardown wait is bounded, and any
// unexpected failure resets isFinishing so the user can retry or leave.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/ai/services/recording.service.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/modules/live_activity/live_activity.dart';
import 'package:rexone_mobile/services/media.service.dart';
import 'package:rexone_mobile/services/recording_session.service.dart';
import 'package:rexone_mobile/services/socket.service.dart';
import 'package:rexone_mobile/services/speech.service.dart';

import '../../mocks/test_services.dart';

/// Notification updates must not touch the foreground-service plugin.
class _FakeRecordingSessionService extends RecordingSessionService {
  @override
  Future<void> start({required String title}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> markRunning(String elapsed) async {}

  @override
  Future<void> markPaused(String elapsed) async {}
}

/// stopListening never completes — simulates a stalled audio teardown.
class _HangingSpeechService extends FakeSpeechService {
  @override
  Future<void> stopListening() => Completer<void>().future;
}

/// stopListening throws immediately.
class _ThrowingSpeechService extends FakeSpeechService {
  @override
  Future<void> stopListening() async {
    throw StateError('audio teardown blew up');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<RecordingService>(FakeRecordingService());
    Get.put<MediaService>(FakeMediaService());
    Get.put<HomeService>(FakeHomeService());
    Get.put<RecordingSessionService>(_FakeRecordingSessionService());
    Get.put<SocketService>(FakeSocketService());
  });

  tearDown(() {
    LiveActivityController.teardownTimeout = const Duration(seconds: 12);
    LiveActivityController.uploadWaitTimeout = const Duration(seconds: 20);
    Get.reset();
  });

  test('a throwing teardown step cannot wedge the finish', () async {
    Get.put<SpeechService>(_ThrowingSpeechService());
    final controller = LiveActivityController();
    controller.recordingId.value = 'rec-1';

    await controller.finishRecording().timeout(const Duration(seconds: 5));

    expect(controller.isFinishing.value, isFalse);
  });

  test('a hanging teardown step cannot wedge the finish', () async {
    LiveActivityController.teardownTimeout = const Duration(milliseconds: 80);
    Get.put<SpeechService>(_HangingSpeechService());
    final fakeRecording = Get.find<RecordingService>() as FakeRecordingService;
    fakeRecording.finishResponse = ApiResponse.error(
      message: 'finish failed',
      statusCode: 500,
      error: 'boom',
    );

    final controller = LiveActivityController();
    controller.recordingId.value = 'rec-1';

    final watch = Stopwatch()..start();
    await controller.finishRecording().timeout(const Duration(seconds: 5));
    watch.stop();

    // The finish moved past the hung step (bounded by teardownTimeout) and
    // reset state instead of trapping the user on the recording screen.
    expect(controller.isFinishing.value, isFalse);
    expect(watch.elapsed, lessThan(const Duration(seconds: 4)));
  });
}
