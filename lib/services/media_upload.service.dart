// lib/services/media_upload.service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rexone_mobile/config/app.config.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/api.service.dart';
import 'package:rexone_mobile/services/media_upload_notification.service.dart';
import 'package:rexone_mobile/services/storage.service.dart';

import '../modules/auth/auth.dart';

class MediaUploadException implements Exception {
  final String message;
  const MediaUploadException(this.message);

  @override
  String toString() => message;
}

/// Thin seam over `FileDownloader` so unit tests can drive the queue without
/// the native background pipeline.
abstract class UploadTransport {
  void registerCallbacks({
    required String group,
    required void Function(TaskStatusUpdate update) onStatus,
    required void Function(TaskProgressUpdate update) onProgress,
  });

  Future<void> configure();

  Future<void> start();

  Future<bool> enqueue(UploadTask task);

  Future<void> cancelTasksWithIds(List<String> ids);

  Future<TaskRecord?> recordForId(String taskId);

  Future<void> trackTasks(String group);
}

class BackgroundUploaderTransport implements UploadTransport {
  const BackgroundUploaderTransport();

  @override
  void registerCallbacks({
    required String group,
    required void Function(TaskStatusUpdate update) onStatus,
    required void Function(TaskProgressUpdate update) onProgress,
  }) {
    FileDownloader().registerCallbacks(
      group: group,
      taskStatusCallback: onStatus,
      taskProgressCallback: onProgress,
    );
  }

  @override
  Future<void> configure() async {
    await FileDownloader().configure(
      androidConfig: [(Config.runInForeground, Config.always)],
    );
  }

  @override
  Future<void> start() async {
    try {
      await FileDownloader().start(autoCleanDatabase: true);
    } catch (error) {
      // Already started by the offline-download stack — safe to continue.
      debugPrint('ℹ️ [MediaUploadService] downloader start skipped: $error');
    }
  }

  @override
  Future<bool> enqueue(UploadTask task) => FileDownloader().enqueue(task);

  @override
  Future<void> cancelTasksWithIds(List<String> ids) =>
      FileDownloader().cancelTasksWithIds(ids);

  @override
  Future<TaskRecord?> recordForId(String taskId) =>
      FileDownloader().database.recordForId(taskId);

  @override
  Future<void> trackTasks(String group) async {
    await FileDownloader().trackTasksInGroup(
      group,
      markDownloadedComplete: false,
    );
    // Flushes updates that were processed while the app was backgrounded.
    await FileDownloader().resumeFromBackground();
  }
}

/// Background upload queue for atom files, recordings, and attachments.
///
/// The picked file is copied into app storage, enqueued with the background
/// downloader (which uploads it even when the app is backgrounded), and when
/// the upload lands a follow-up runs — creating the atom
/// (`from-asset`) or attaching the file to an existing atom — followed by a
/// local notification. No screen ever waits on the network.
class MediaUploadService extends GetxService {
  MediaUploadService({UploadTransport? transport}) : _transportOverride = transport;

  final UploadTransport? _transportOverride;
  late final UploadTransport _transport;

  late final StorageService _storage;
  late final MediaUploadNotificationService _notifications;

  /// Test seam: replaces the real follow-up network calls.
  @visibleForTesting
  Future<String?> Function(MediaUploadModel entry, String assetId)?
      debugFollowUpOverride;

  final RxMap<String, MediaUploadModel> entries =
      <String, MediaUploadModel>{}.obs;

  final Map<String, double> _lastPersistedProgress = {};
  Directory? _uploadsDir;
  bool _started = false;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _notifications = Get.find<MediaUploadNotificationService>();
    _transport = _transportOverride ?? const BackgroundUploaderTransport();
  }

  /// Must run once at app startup (after the first frame) before uploads
  /// are enqueued. Safe to call again.
  Future<void> initializeUploader() async {
    if (_started) {
      await _ensureDir();
      return;
    }

    _transport.registerCallbacks(
      group: MediaUploadConstants.uploadTaskGroup,
      onStatus: _onTaskStatusUpdate,
      onProgress: _onTaskProgressUpdate,
    );
    await _transport.configure();
    await _transport.start();
    _started = true;

    await _ensureDir();
    _loadIndex();
    await _reconcile();

    // Deliver status updates for tasks that ran (or finished) while the app
    // was not running, so their follow-ups complete now.
    try {
      await _transport.trackTasks(MediaUploadConstants.uploadTaskGroup);
    } catch (error) {
      debugPrint('⚠️ [MediaUploadService] trackTasks skipped: $error');
    }

    await retryPendingFollowUps();
  }

  // ============================================================
  // PUBLIC API
  // ============================================================

  List<MediaUploadModel> get orderedEntries {
    final list = entries.values.toList();
    list.sort(
      (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
    );
    return list;
  }

  int get activeCount => entries.values.where((e) => e.isActive).length;

  int get pendingCount => entries.values
      .where((e) => e.isActive || e.needsFollowUp || e.isFailed)
      .length;

  /// Copies [filePath] into app storage and queues the background upload.
  /// Returns immediately — the upload continues without any screen waiting.
  Future<MediaUploadModel> enqueueUpload({
    required String filePath,
    required String filename,
    String? type,
    String folder = 'atoms',
    int? durationSecs,
    String followUpType = MediaUploadConstants.followUpNone,
    String? categoryId,
    String? language,
    String? atomId,
    bool deleteSourceAfter = false,
  }) async {
    await _ensureDir();

    final source = File(filePath);
    if (!await source.exists()) {
      throw const MediaUploadException('File is no longer available');
    }

    final taskId = _buildTaskId();
    final safeName = _safeFileName(filename);
    final storedDir = Directory(
      '${_uploadsDir!.path}/$taskId',
    );
    await storedDir.create(recursive: true);
    final stored = File('${storedDir.path}/$safeName');
    await source.copy(stored.path);

    final entry = MediaUploadModel(
      taskId: taskId,
      name: filename,
      displayName: filename,
      type: type,
      folder: folder,
      durationSecs: durationSecs,
      state: MediaUploadConstants.stateQueued,
      followUpType: followUpType,
      categoryId: categoryId,
      language: language,
      atomId: atomId,
      localPath: stored.path,
      sourcePath: deleteSourceAfter ? filePath : null,
      deleteSourceAfter: deleteSourceAfter,
      createdAt: DateTime.now(),
    );
    _setEntry(entry);

    final queued = await _enqueueTask(entry, safeName);
    if (!queued) {
      _setEntry(
        entry.copyWith(
          state: MediaUploadConstants.stateFailed,
          errorMessage: 'Could not queue the upload',
        ),
      );
    }
    return entries[taskId] ?? entry;
  }

  /// Retries a failed/interrupted upload, or re-runs a pending follow-up.
  Future<void> retryUpload(String taskId) async {
    final entry = entries[taskId];
    if (entry == null || entry.isDone) return;

    if (entry.needsFollowUp && entry.hasUploadedAsset) {
      _setEntry(entry.copyWith(state: MediaUploadConstants.stateProcessing));
      await _runFollowUp(entries[taskId]!);
      return;
    }

    final file = File(entry.localPath);
    if (!await file.exists()) {
      _setEntry(
        entry.copyWith(
          state: MediaUploadConstants.stateFailed,
          errorMessage: 'The queued file is no longer available',
        ),
      );
      return;
    }

    final safeName = _safeFileName(entry.name);
    _setEntry(
      entry.copyWith(
        state: MediaUploadConstants.stateQueued,
        progress: 0,
        secureRetryDone: false,
        clearErrorMessage: true,
      ),
    );
    final queued = await _enqueueTask(entries[taskId]!, safeName);
    if (!queued) {
      _setEntry(
        entries[taskId]!.copyWith(
          state: MediaUploadConstants.stateFailed,
          errorMessage: 'Could not queue the upload',
        ),
      );
    }
  }

  /// Cancels an in-flight upload and removes its entry + files.
  Future<void> cancelUpload(String taskId) async {
    final entry = entries[taskId];
    if (entry == null) return;
    try {
      await _transport.cancelTasksWithIds([taskId]);
    } catch (_) {}
    await _cleanupFiles(entry);
    entries.remove(taskId);
    entries.refresh();
    _lastPersistedProgress.remove(taskId);
    _persistIndex();
  }

  /// Runs every follow-up that is still pending (call after app start and
  /// whenever connectivity returns).
  Future<void> retryPendingFollowUps() async {
    for (final entry in entries.values.toList()) {
      if (!entry.needsFollowUp || !entry.hasUploadedAsset) continue;
      _setEntry(entry.copyWith(state: MediaUploadConstants.stateProcessing));
      await _runFollowUp(entries[entry.taskId]!);
    }
  }

  // ============================================================
  // TASK BUILDING
  // ============================================================

  Future<bool> _enqueueTask(MediaUploadModel entry, String safeName) async {
    final task = _buildTask(entry, safeName);
    try {
      return await _transport.enqueue(task);
    } catch (error) {
      debugPrint('❌ [MediaUploadService] enqueue failed: $error');
      return false;
    }
  }

  UploadTask _buildTask(MediaUploadModel entry, String safeName) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final token = _currentToken();

    final fields = <String, String>{
      if ((entry.type ?? '').isNotEmpty) AssetKeys.type: entry.type!,
      if (entry.folder.isNotEmpty) AssetKeys.folder: entry.folder,
      if (entry.durationSecs != null)
        AssetKeys.durationSecs: entry.durationSecs!.toString(),
    };

    return UploadTask(
      taskId: entry.taskId,
      url: '$base${ServerRoutes.uploadAsset}',
      filename: safeName,
      directory: '${MediaUploadConstants.uploadsDirName}/${entry.taskId}',
      baseDirectory: BaseDirectory.applicationSupport,
      httpRequestMethod: 'POST',
      fileField: AssetKeys.file,
      fields: fields,
      headers: {
        if (token.isNotEmpty)
          AuthHeaders.authorization: '${AppConstants.bearerPrefix}$token',
        // Sessions are platform-scoped server-side (active_session:<id>:<platform>);
        // without X-Platform the request resolves to 'web' and the session check
        // 401s ("Active session not found") even with a valid token.
        AuthHeaders.platform: AppConstants.currentPlatform,
        AuthHeaders.accept: AppConstants.contentTypeJson,
      },
      group: MediaUploadConstants.uploadTaskGroup,
      updates: Updates.statusAndProgress,
      displayName: entry.displayName.isNotEmpty ? entry.displayName : entry.name,
      metaData: jsonEncode({
        MediaUploadConstants.metaTaskId: entry.taskId,
      }),
    );
  }

  String _currentToken() {
    try {
      var token = '';
      if (Get.isRegistered<AuthController>()) {
        token = Get.find<AuthController>().authToken.value;
      }
      if (token.isEmpty) {
        token = _storage.getToken() ?? '';
      }
      return token;
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // CALLBACKS
  // ============================================================

  void _onTaskProgressUpdate(TaskProgressUpdate update) {
    final entry = entries[update.task.taskId];
    if (entry == null || entry.isDone || entry.needsFollowUp) return;

    final progress = update.progress.clamp(0.0, 1.0);
    _setEntry(
      entry.copyWith(
        state: entry.isFailed
            ? MediaUploadConstants.stateUploading
            : entry.state == MediaUploadConstants.stateQueued
                ? MediaUploadConstants.stateUploading
                : entry.state,
        progress: progress,
      ),
      persistProgress: _shouldPersistProgress(entry.taskId, progress),
    );

    unawaited(
      _notifications.onUploadProgress(
        taskId: entry.taskId,
        title: entry.displayName.isNotEmpty ? entry.displayName : entry.name,
        progress: progress,
      ),
    );
  }

  Future<void> _onTaskStatusUpdate(TaskStatusUpdate update) async {
    final entry = entries[update.task.taskId];
    if (entry == null || entry.isDone) return;

    switch (update.status) {
      case TaskStatus.enqueued:
        if (entry.isFailed || entry.needsFollowUp) return;
        _setEntry(
          entry.copyWith(
            state: MediaUploadConstants.stateQueued,
            clearErrorMessage: true,
          ),
        );
      case TaskStatus.running:
        if (entry.needsFollowUp) return;
        _setEntry(
          entry.copyWith(
            state: MediaUploadConstants.stateUploading,
            clearErrorMessage: true,
          ),
        );
      case TaskStatus.complete:
        await _handleUploadComplete(entry, update.responseBody);
      case TaskStatus.canceled:
        await _handleCanceled(entry);
      case TaskStatus.failed:
      case TaskStatus.notFound:
        await _failEntry(
          entry,
          update.exception?.description ??
              'Upload failed (${update.status.name})',
          statusCode: update.responseStatusCode,
        );
      default:
        break;
    }
  }

  Future<void> _handleUploadComplete(
    MediaUploadModel entry,
    String? responseBody,
  ) async {
    final assetId = _extractAssetId(responseBody);
    if (assetId.isEmpty) {
      _setEntry(
        entry.copyWith(
          state: MediaUploadConstants.stateNeedsFollowUp,
          errorMessage:
              'Uploaded, but the server response could not be read. Tap retry.',
        ),
      );
      return;
    }

    _setEntry(
      entry.copyWith(
        assetId: assetId,
        state: MediaUploadConstants.stateProcessing,
        progress: 1,
        clearErrorMessage: true,
      ),
    );
    await _runFollowUp(entries[entry.taskId]!);
  }

  Future<void> _runFollowUp(MediaUploadModel entry) async {
    final assetId = entry.assetId ?? '';
    if (assetId.isEmpty) return;

    try {
      String? atomId;

      if (debugFollowUpOverride != null) {
        atomId = await debugFollowUpOverride!(entry, assetId);
      } else if (entry.followUpType ==
          MediaUploadConstants.followUpAtomFromAsset) {
        atomId = await _createAtomFromAsset(entry, assetId);
      } else if (entry.followUpType ==
          MediaUploadConstants.followUpAttachToAtom) {
        final target = entry.atomId ?? '';
        if (target.isEmpty) {
          throw const MediaUploadException('Missing atom to attach to');
        }
        await _attachAssetToAtom(target, assetId);
        atomId = target;
      }

      final done = entries[entry.taskId]!.copyWith(
        state: MediaUploadConstants.stateDone,
        atomId: atomId ?? entry.atomId,
        progress: 1,
        clearErrorMessage: true,
      );
      _setEntry(done);
      _lastPersistedProgress.remove(entry.taskId);
      await _cleanupFiles(done);
      await _notifications.onUploadFinished(
        taskId: done.taskId,
        title: done.displayName.isNotEmpty ? done.displayName : done.name,
        success: true,
      );
    } catch (error) {
      _setEntry(
        entries[entry.taskId]!.copyWith(
          state: MediaUploadConstants.stateNeedsFollowUp,
          errorMessage: 'Uploaded. Finishing touches pending: $error',
        ),
      );
    }
  }

  Future<String?> _createAtomFromAsset(
    MediaUploadModel entry,
    String assetId,
  ) async {
    final api = Get.find<ApiService>();
    final body = <String, dynamic>{
      AtomKeys.assetId: assetId,
      if ((entry.categoryId ?? '').isNotEmpty)
        CategoryKeys.categoryId: entry.categoryId!,
      if ((entry.language ?? '').isNotEmpty)
        AtomKeys.language: entry.language!,
    };
    final response =
        await api.post(ServerRoutes.atomFromAsset, body, showLoading: false);
    final parsed = api.parseResponse<Map<String, dynamic>>(response, (data) {
      final record = data is Map && data[AtomKeys.atom] is Map
          ? data[AtomKeys.atom]
          : data;
      return record is Map
          ? Map<String, dynamic>.from(record)
          : <String, dynamic>{};
    });
    if (!parsed.success) {
      throw MediaUploadException(parsed.error ?? parsed.message);
    }
    final id = parsed.data?['id']?.toString() ?? '';
    return id.isEmpty ? null : id;
  }

  Future<void> _attachAssetToAtom(String atomId, String assetId) async {
    final api = Get.find<ApiService>();
    final response = await api.post(
      ServerRoutes.atomAssets(atomId),
      {AtomKeys.assetId: assetId},
      showLoading: false,
    );
    if (!response.isOk) {
      throw const MediaUploadException('Could not attach the file');
    }
  }

  Future<void> _failEntry(
    MediaUploadModel entry,
    String message, {
    int? statusCode,
  }) async {
    // Stale-session 401s are recoverable: the task captured its Authorization
    // header at enqueue time (see _buildTask), but the server only honors the
    // user's LATEST token (the "active session" rule) — signing in again on
    // any device rotates it, leaving older queued uploads on a dead token.
    // Re-enqueue once with the token the app holds right now instead of
    // parking the upload until someone taps retry.
    final staleSession =
        statusCode == 401 && !entry.secureRetryDone && !entry.hasUploadedAsset;
    if (staleSession) {
      final retried = entry.copyWith(
        state: MediaUploadConstants.stateQueued,
        progress: 0,
        secureRetryDone: true,
        clearErrorMessage: true,
      );
      _setEntry(retried);
      final queued = await _enqueueTask(retried, _safeFileName(retried.name));
      if (queued) {
        debugPrint(
          '♻️ [MediaUploadService] re-queued ${entry.taskId} with the current session token',
        );
        return;
      }
    }

    final failureMessage = staleSession
        ? 'Session was renewed — tap retry to upload again'
        : message;
    _setEntry(
      entry.copyWith(
        state: MediaUploadConstants.stateFailed,
        errorMessage: failureMessage,
      ),
    );
    unawaited(
      _notifications.onUploadFinished(
        taskId: entry.taskId,
        title: entry.displayName.isNotEmpty ? entry.displayName : entry.name,
        success: false,
        errorMessage: failureMessage,
      ),
    );
  }

  Future<void> _handleCanceled(MediaUploadModel entry) async {
    await _cleanupFiles(entry);
    entries.remove(entry.taskId);
    entries.refresh();
    _lastPersistedProgress.remove(entry.taskId);
    _persistIndex();
  }

  // ============================================================
  // RECONCILE / INDEX
  // ============================================================

  Future<void> _reconcile() async {
    for (final entry in entries.values.toList()) {
      if (entry.isDone) continue;
      try {
        final record = await _transport.recordForId(entry.taskId);
        if (record == null) {
          if (entry.state == MediaUploadConstants.stateQueued ||
              entry.state == MediaUploadConstants.stateUploading) {
            _setEntry(
              entry.copyWith(
                state: MediaUploadConstants.stateFailed,
                errorMessage: 'Upload interrupted',
              ),
            );
          }
          continue;
        }

        switch (record.status) {
          case TaskStatus.complete:
            if (!entry.hasUploadedAsset &&
                entry.state != MediaUploadConstants.stateProcessing) {
              // Response body is replayed by trackTasks when available;
              // if not, the entry stays retryable.
            }
          case TaskStatus.failed:
          case TaskStatus.notFound:
            if (!entry.isFailed) {
              _failEntry(
                entry,
                record.exception?.description ?? 'Upload failed',
              );
            }
          default:
            break;
        }
      } catch (error) {
        debugPrint('⚠️ [MediaUploadService] reconcile skip: $error');
      }
    }
  }

  void _loadIndex() {
    final raw = _storage.getMediaUploadsIndex();
    if (raw == null || raw.isEmpty) return;

    final loaded = <String, MediaUploadModel>{};
    raw.forEach((key, value) {
      if (value is! Map) return;
      final entry = MediaUploadModel.fromJson(
        Map<String, dynamic>.from(value),
      );
      if (entry.taskId.isEmpty) return;
      loaded[entry.taskId] = entry;
    });
    entries.assignAll(loaded);
  }

  void _persistIndex() {
    final index = entries.map(
      (taskId, entry) => MapEntry(taskId, entry.toJson()),
    );
    _storage.saveMediaUploadsIndex(index);
  }

  void _setEntry(MediaUploadModel entry, {bool persistProgress = true}) {
    entries[entry.taskId] = entry;
    entries.refresh();
    if (persistProgress) {
      _persistIndex();
    }
  }

  bool _shouldPersistProgress(String taskId, double progress) {
    final last = _lastPersistedProgress[taskId] ?? -1;
    if ((progress - last).abs() < 0.1 && progress < 1) return false;
    _lastPersistedProgress[taskId] = progress;
    return true;
  }

  // ============================================================
  // FILES
  // ============================================================

  Future<void> _ensureDir() async {
    final support = await getApplicationSupportDirectory();
    _uploadsDir = Directory(
      '${support.path}/${MediaUploadConstants.uploadsDirName}',
    );
    if (!await _uploadsDir!.exists()) {
      await _uploadsDir!.create(recursive: true);
    }
  }

  Future<void> _cleanupFiles(MediaUploadModel entry) async {
    try {
      if (entry.localPath.isNotEmpty) {
        final file = File(entry.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        final dir = file.parent;
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
      if (entry.deleteSourceAfter && (entry.sourcePath ?? '').isNotEmpty) {
        final source = File(entry.sourcePath!);
        if (await source.exists()) {
          await source.delete();
        }
      }
    } catch (error) {
      debugPrint('⚠️ [MediaUploadService] cleanup skipped: $error');
    }
  }

  String _buildTaskId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final salt = Random().nextInt(0x7fffffff);
    return 'upload_${micros}_$salt';
  }

  /// Keeps the original extension (the downloader derives the mime type from
  /// it) and replaces anything exotic so the multipart filename stays safe.
  String _safeFileName(String filename) {
    var name = filename.trim();
    if (name.isEmpty) return 'file';

    final dot = name.lastIndexOf('.');
    var ext = '';
    if (dot > 0 && dot < name.length - 1 && name.length - dot <= 8) {
      ext = name.substring(dot);
      name = name.substring(0, dot);
    }

    final sanitized = name
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final base = sanitized.isEmpty ? 'file' : sanitized;
    final trimmed = base.length > 60 ? base.substring(0, 60) : base;
    return '$trimmed$ext';
  }

  /// Extracts the asset id from the upload endpoint's JSON response.
  String _extractAssetId(String? responseBody) {
    if (responseBody == null || responseBody.isEmpty) return '';
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map) return '';
      final data = decoded['data'];
      if (data is Map) {
        final id = data['id'];
        if (id != null && id.toString().isNotEmpty) return id.toString();
        final asset = data['asset'];
        if (asset is Map && asset['id'] != null) {
          return asset['id'].toString();
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }
}
