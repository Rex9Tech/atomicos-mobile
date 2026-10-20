// test/modules/live_activity/live_activity_captions_test.dart
//
// Captions always start off each recording session (credit confirm on enable).
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/ai/services/recording.service.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/modules/live_activity/live_activity.dart';
import 'package:rexone_mobile/services/services.dart';

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

  setUp(() {
    Get.testMode = true;
    Get.put<SpeechService>(FakeSpeechService());
    Get.put<RecordingService>(FakeRecordingService());
    Get.put<MediaService>(FakeMediaService());
    Get.put<HomeService>(FakeHomeService());
    Get.put<MediaUploadService>(FakeMediaUploadService());
    Get.put<RecordingSessionService>(FakeRecordingSessionService());
    Get.put<SocketService>(FakeSocketService());
    Get.put<StorageService>(FakeStorageService());
  });

  tearDown(Get.reset);

  test('captions default to off', () {
    final controller = Get.put(LiveActivityController());
    expect(controller.captionsVisible.value, isFalse);
  });

  test('ignores a previously persisted on preference', () {
    final storage = Get.find<StorageService>();
    storage.setCaptionsVisible(true);

    final controller = Get.put(LiveActivityController());
    expect(controller.captionsVisible.value, isFalse);
    expect(storage.getCaptionsVisible(), isFalse);
  });

  test('toggle flips visibility for the session', () async {
    final controller = Get.put(LiveActivityController());

    await controller.toggleCaptions();
    expect(controller.captionsVisible.value, isTrue);

    await controller.toggleCaptions();
    expect(controller.captionsVisible.value, isFalse);
  });
}
