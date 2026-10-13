import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/media_upload.service.dart';
import 'package:rexone_mobile/services/media_upload_notification.service.dart';
import 'package:rexone_mobile/services/push_notification.service.dart';
import 'package:rexone_mobile/services/storage.service.dart';

import '../mocks/test_services.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => '$root/tmp';

  @override
  Future<String?> getApplicationDocumentsPath() async => '$root/docs';

  @override
  Future<String?> getLibraryPath() async => '$root/library';
}

class _FakeMediaUploadNotificationService
    extends MediaUploadNotificationService {
  final List<String> finished = [];
  final List<bool> finishedSuccess = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> onUploadFinished({
    required String taskId,
    required String title,
    required bool success,
    String? errorMessage,
  }) async {
    finished.add(title);
    finishedSuccess.add(success);
  }
}

class _FakeUploadTransport implements UploadTransport {
  final List<UploadTask> enqueued = [];
  final Map<String, TaskRecord> records = {};

  void Function(TaskStatusUpdate update)? statusCallback;
  void Function(TaskProgressUpdate update)? progressCallback;

  @override
  void registerCallbacks({
    required String group,
    required void Function(TaskStatusUpdate update) onStatus,
    required void Function(TaskProgressUpdate update) onProgress,
  }) {
    statusCallback = onStatus;
    progressCallback = onProgress;
  }

  @override
  Future<void> configure() async {}

  @override
  Future<void> start() async {}

  @override
  Future<bool> enqueue(UploadTask task) async {
    enqueued.add(task);
    return true;
  }

  @override
  Future<void> cancelTasksWithIds(List<String> ids) async {
    records.removeWhere((key, _) => ids.contains(key));
  }

  @override
  Future<TaskRecord?> recordForId(String taskId) async => records[taskId];

  @override
  Future<void> trackTasks(String group) async {}

  void emitProgress(Task task, double progress) {
    progressCallback?.call(
      TaskProgressUpdate(task, progress, 0, 0),
    );
  }

  void emitStatus(
    Task task,
    TaskStatus status, {
    String? responseBody,
  }) {
    statusCallback?.call(
      TaskStatusUpdate(task, status, null, responseBody),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Waits for an async condition with a bounded real-time loop (file IO and
  /// follow-up chains are not pure microtasks).
  Future<void> waitFor(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) break;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  late Directory tempRoot;
  late FakeStorageService fakeStorage;
  late _FakeUploadTransport fakeTransport;
  late _FakeMediaUploadNotificationService fakeNotifications;
  late MediaUploadService uploads;

  setUp(() async {
    Get.testMode = true;
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://test.atomicos.local\n',
    );

    tempRoot = Directory.systemTemp.createTempSync('media_upload_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);

    fakeStorage = FakeStorageService();
    fakeStorage.setToken('tok_123');
    Get.put<StorageService>(fakeStorage);

    Get.put<PushNotificationService>(FakePushNotificationService());

    fakeNotifications = _FakeMediaUploadNotificationService();
    Get.put<MediaUploadNotificationService>(fakeNotifications);

    fakeTransport = _FakeUploadTransport();
    uploads = Get.put(MediaUploadService(transport: fakeTransport));
    await uploads.initializeUploader();
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
    Get.reset();
  });

  File createSourceFile([String name = 'demo.mp3']) {
    final file = File('${tempRoot.path}/$name');
    file.writeAsStringSync('payload-bytes');
    return file;
  }

  group('MediaUploadModel', () {
    test('toJson/fromJson round-trip preserves fields', () {
      final original = MediaUploadModel(
        taskId: 'upload_1',
        name: 'meeting.mp3',
        displayName: 'meeting.mp3',
        type: AssetKeys.typeAudio,
        folder: 'recordings',
        durationSecs: 61,
        state: MediaUploadConstants.stateDone,
        progress: 1,
        assetId: 'ast_1',
        atomId: 'atom_9',
        followUpType: MediaUploadConstants.followUpAttachToAtom,
        localPath: '/tmp/upload_1/meeting.mp3',
        createdAt: DateTime.utc(2026, 10, 14, 5),
      );

      final restored = MediaUploadModel.fromJson(original.toJson());

      expect(restored.taskId, 'upload_1');
      expect(restored.type, AssetKeys.typeAudio);
      expect(restored.folder, 'recordings');
      expect(restored.durationSecs, 61);
      expect(restored.state, MediaUploadConstants.stateDone);
      expect(restored.isDone, isTrue);
      expect(restored.assetId, 'ast_1');
      expect(restored.atomId, 'atom_9');
      expect(
        restored.followUpType,
        MediaUploadConstants.followUpAttachToAtom,
      );
    });
  });

  group('MediaUploadService', () {
    test('enqueueUpload copies the file, persists, and builds the task',
        () async {
      final source = createSourceFile();

      final entry = await uploads.enqueueUpload(
        filePath: source.path,
        filename: 'demo.mp3',
        type: AssetKeys.typeAudio,
        folder: 'recordings',
        durationSecs: 12,
      );

      expect(entry.state, MediaUploadConstants.stateQueued);
      expect(entry.localPath, isNotEmpty);
      expect(File(entry.localPath).existsSync(), isTrue);

      // Persisted through the storage index.
      final index = fakeStorage.getMediaUploadsIndex();
      expect(index, isNotNull);
      expect(index!.containsKey(entry.taskId), isTrue);

      // Task built against the real endpoint with auth + form fields.
      final task = fakeTransport.enqueued.single;
      expect(task.taskId, entry.taskId);
      expect(task.url, contains(ServerRoutes.uploadAsset));
      expect(task.url, startsWith('https://test.atomicos.local'));
      expect(task.httpRequestMethod, 'POST');
      expect(task.fileField, AssetKeys.file);
      expect(task.fields[AssetKeys.type], AssetKeys.typeAudio);
      expect(task.fields[AssetKeys.folder], 'recordings');
      expect(task.fields[AssetKeys.durationSecs], '12');
      expect(
        task.headers[AuthHeaders.authorization],
        '${AppConstants.bearerPrefix}tok_123',
      );
      expect(task.group, MediaUploadConstants.uploadTaskGroup);
    });

    test('progress and completion finalize a no-follow-up upload', () async {
      final source = createSourceFile();
      final entry = await uploads.enqueueUpload(
        filePath: source.path,
        filename: 'demo.mp3',
      );
      final task = fakeTransport.enqueued.single;
      final storedPath = entry.localPath;

      fakeTransport.emitProgress(task, 0.5);
      await pumpEventQueue();
      expect(
        uploads.entries[entry.taskId]!.state,
        MediaUploadConstants.stateUploading,
      );
      expect(uploads.entries[entry.taskId]!.progress, closeTo(0.5, 0.001));

      fakeTransport.emitStatus(
        task,
        TaskStatus.complete,
        responseBody:
            '{"status":{"code":200},"data":{"id":"ast_done"}}',
      );
      await waitFor(() => fakeNotifications.finishedSuccess.isNotEmpty);

      final done = uploads.entries[entry.taskId]!;
      expect(done.isDone, isTrue);
      expect(done.assetId, 'ast_done');
      // Queued copy is cleaned up after success.
      expect(File(storedPath).existsSync(), isFalse);
      expect(fakeNotifications.finishedSuccess, [true]);
    });

    test('atom_from_asset follow-up runs after completion', () async {
      final source = createSourceFile();
      final entry = await uploads.enqueueUpload(
        filePath: source.path,
        filename: 'demo.mp3',
        followUpType: MediaUploadConstants.followUpAtomFromAsset,
        categoryId: 'cat_1',
        language: 'en',
      );
      uploads.debugFollowUpOverride = (e, assetId) async {
        expect(e.taskId, entry.taskId);
        expect(assetId, 'ast_9');
        return 'atom_42';
      };

      final task = fakeTransport.enqueued.single;
      fakeTransport.emitStatus(
        task,
        TaskStatus.complete,
        responseBody: '{"status":{"code":200},"data":{"id":"ast_9"}}',
      );
      await waitFor(
        () => uploads.entries[entry.taskId]!.isDone,
      );
      // The service fires the completion notification after cleaning up the
      // queued copy — wait for it like the no-follow-up test does.
      await waitFor(() => fakeNotifications.finishedSuccess.isNotEmpty);

      final done = uploads.entries[entry.taskId]!;
      expect(done.isDone, isTrue);
      expect(done.atomId, 'atom_42');
      expect(fakeNotifications.finishedSuccess, [true]);
    });

    test('follow-up failure keeps the file and retry finishes it', () async {
      final source = createSourceFile();
      final entry = await uploads.enqueueUpload(
        filePath: source.path,
        filename: 'demo.mp3',
        followUpType: MediaUploadConstants.followUpAtomFromAsset,
      );
      uploads.debugFollowUpOverride =
          (e, assetId) async => throw const MediaUploadException('offline');

      final task = fakeTransport.enqueued.single;
      fakeTransport.emitStatus(
        task,
        TaskStatus.complete,
        responseBody: '{"status":{"code":200},"data":{"id":"ast_9"}}',
      );
      await waitFor(
        () => uploads.entries[entry.taskId]!.needsFollowUp,
      );

      final pending = uploads.entries[entry.taskId]!;
      expect(pending.needsFollowUp, isTrue);
      expect(File(pending.localPath).existsSync(), isTrue);
      expect(fakeNotifications.finishedSuccess, isEmpty);

      uploads.debugFollowUpOverride = (e, assetId) async => 'atom_77';
      await uploads.retryUpload(entry.taskId);
      await waitFor(() => uploads.entries[entry.taskId]!.isDone);

      expect(uploads.entries[entry.taskId]!.isDone, isTrue);
      expect(uploads.entries[entry.taskId]!.atomId, 'atom_77');
    });

    test('failed upload keeps entry retryable and re-enqueues', () async {
      final source = createSourceFile();
      final entry = await uploads.enqueueUpload(
        filePath: source.path,
        filename: 'demo.mp3',
      );
      final task = fakeTransport.enqueued.single;

      fakeTransport.emitStatus(task, TaskStatus.failed);
      await waitFor(() => fakeNotifications.finishedSuccess.isNotEmpty);

      final failed = uploads.entries[entry.taskId]!;
      expect(failed.isFailed, isTrue);
      expect(File(failed.localPath).existsSync(), isTrue);
      expect(fakeNotifications.finishedSuccess, [false]);

      await uploads.retryUpload(entry.taskId);
      await waitFor(
        () => uploads.entries[entry.taskId]!.state ==
            MediaUploadConstants.stateQueued,
      );

      expect(
        uploads.entries[entry.taskId]!.state,
        MediaUploadConstants.stateQueued,
      );
      expect(fakeTransport.enqueued.length, 2);
    });
  });
}
