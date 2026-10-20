// test/modules/live_activity/live_activity_captions_test.dart
//
// Captions on/off on the live recording sheet is a DISPLAY toggle: hiding the
// caption panel must never stop live STT (the finished atom keeps its
// transcript), and the choice persists across sessions (default: on).
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

  test('captions default to visible', () {
    final controller = LiveActivityController();
    expect(controller.captionsVisible.value, isTrue);
  });

  test('toggle flips visibility and persists the choice', () {
    final controller = LiveActivityController();
    final storage = Get.find<StorageService>();

    controller.toggleCaptions();
    expect(controller.captionsVisible.value, isFalse);
    expect(storage.getCaptionsVisible(), isFalse);

    controller.toggleCaptions();
    expect(controller.captionsVisible.value, isTrue);
    expect(storage.getCaptionsVisible(), isTrue);
  });

  test('storage round-trips the captions preference', () {
    final storage = Get.find<StorageService>();
    expect(storage.getCaptionsVisible(), isTrue); // never toggled -> on

    storage.setCaptionsVisible(false);
    expect(storage.getCaptionsVisible(), isFalse);
  });
}