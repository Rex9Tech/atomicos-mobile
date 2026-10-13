// test/modules/live_activity/live_activity_attachments_test.dart
//
// Recording-sheet attachments: files staged while recording must survive the
// session — each one is uploaded and attached to the atom the finish creates,
// riding the same upload → attach rail as the captured audio.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/ai/models/recording.model.dart';
import 'package:rexone_mobile/modules/ai/services/recording.service.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/modules/live_activity/live_activity.dart';
import 'package:rexone_mobile/services/media.service.dart';
import 'package:rexone_mobile/services/media_upload.service.dart';
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

  late FakeSpeechService speech;
  late FakeRecordingService recording;
  late FakeMediaService media;
  late FakeHomeService home;

  setUp(() {
    Get.testMode = true;
    speech = FakeSpeechService();
    recording = FakeRecordingService();
    media = FakeMediaService();
    home = FakeHomeService();
    Get.put<SpeechService>(speech);
    Get.put<RecordingService>(recording);
    Get.put<MediaService>(media);
    Get.put<HomeService>(home);
    Get.put<MediaUploadService>(FakeMediaUploadService());
    Get.put<RecordingSessionService>(FakeRecordingSessionService());
    Get.put<SocketService>(FakeSocketService());
  });

  tearDown(Get.reset);

  test('staged attachments dedupe by path and can be removed', () {
    final controller = LiveActivityController();

    controller.stageAttachment(path: '/tmp/agenda.pdf', name: 'agenda.pdf');
    controller.stageAttachment(path: '/tmp/agenda.pdf', name: 'agenda.pdf');
    controller.stageAttachment(path: '/tmp/slides.pptx', name: 'slides.pptx');

    expect(controller.attachments.length, 2);

    controller.removeAttachment(controller.attachments.first);

    expect(controller.attachments.length, 1);
    expect(controller.attachments.single.name, 'slides.pptx');
  });

  test('a blank path is rejected quietly', () {
    final controller = LiveActivityController();

    controller.stageAttachment(path: null, name: 'x');
    controller.stageAttachment(path: '', name: 'x');

    expect(controller.attachments, isEmpty);
  });

  test('finishRecording queues every staged file for background upload',
      () async {
    speech.captureResultPath = '/tmp/capture.wav';
    recording.finishResponse = ApiResponse.success(
      message: 'Recording finished',
      statusCode: 200,
      data: RecordingModel.fromJson(const {'atom_id': 'atom-9'}),
    );
    final uploads = Get.find<MediaUploadService>() as FakeMediaUploadService;

    final controller = LiveActivityController();
    controller.recordingId.value = 'rec-1';
    controller.stageAttachment(path: '/tmp/agenda.pdf', name: 'agenda.pdf');
    controller.stageAttachment(path: '/tmp/slides.pptx', name: 'slides.pptx');

    await controller.finishRecording();

    // The audio and both attachments all went onto the background queue…
    expect(
      uploads.enqueued.map((e) => e.name),
      containsAll(['recording.wav', 'agenda.pdf', 'slides.pptx']),
    );
    expect(uploads.enqueued.length, 3);
    // …each targeting the atom the finish created, riding the attach rail.
    expect(
      uploads.enqueued.every(
        (e) =>
            e.followUpType == MediaUploadConstants.followUpAttachToAtom &&
            e.atomId == 'atom-9',
      ),
      isTrue,
    );
    // Attachments ride the attachment asset type.
    expect(
      uploads.enqueued.firstWhere((e) => e.name == 'agenda.pdf').type,
      AssetKeys.typeAttachment,
    );
  });

  test('with nothing staged, only the audio is queued', () async {
    speech.captureResultPath = '/tmp/capture.wav';
    recording.finishResponse = ApiResponse.success(
      message: 'Recording finished',
      statusCode: 200,
      data: RecordingModel.fromJson(const {'atom_id': 'atom-9'}),
    );
    final uploads = Get.find<MediaUploadService>() as FakeMediaUploadService;

    final controller = LiveActivityController();
    controller.recordingId.value = 'rec-1';

    await controller.finishRecording();

    expect(uploads.enqueued.map((e) => e.name), ['recording.wav']);
    expect(uploads.enqueued.single.atomId, 'atom-9');
  });
}
