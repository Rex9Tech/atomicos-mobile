import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../ai/services/recording.service.dart';
import '../../home/services/home.service.dart';

/// A file staged on the recording sheet. Uploaded and attached to the
/// recording's atom when the session finishes.
class RecordingAttachment {
  const RecordingAttachment({required this.path, required this.name});

  final String path;
  final String name;
}

/// Drives the live recording sheet: the backend session record, the timer, the
/// live transcript streamed from the microphone through [SpeechService], and
/// the audio capture that is uploaded when the recording ends.
class LiveActivityController extends GetxController {
  final RecordingService _recording = Get.find<RecordingService>();
  final SpeechService _speech = Get.find<SpeechService>();
  final MediaService _media = Get.find<MediaService>();
  final HomeService _home = Get.find<HomeService>();
  final RecordingSessionService _background = Get.find<RecordingSessionService>();
  final SocketService _socket = Get.find<SocketService>();

  final RxString selectedSurface = 'Expanded'.obs;
  final RxBool isRecording = false.obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxnString recordingId = RxnString();
  final RxBool isFinishing = false.obs;
  final noteController = TextEditingController();

  /// Files staged on the sheet while recording; every one is uploaded and
  /// attached to the atom when the session finishes.
  final RxList<RecordingAttachment> attachments = <RecordingAttachment>[].obs;

  /// Transcript text streamed live from the mic while recording.
  final RxString liveTranscript = ''.obs;

  /// Whether the live STT session is running right now.
  final RxBool isTranscriptLive = false.obs;

  /// Set when the live transcript cannot start (offline, no permission…).
  final RxnString transcriptNotice = RxnString();

  Timer? _ticker;
  Worker? _transcriptWorker;
  bool _started = false;

  /// Bounds how long every teardown step of [finishRecording] may wait — a
  /// stalled mic, socket or OEM plugin must never trap the user on the
  /// recording screen. Static so tests can shorten it.
  static Duration teardownTimeout = const Duration(seconds: 12);

  /// How long the finish may wait on the audio upload before moving on — the
  /// request keeps running in the background and the attach broadcasts when
  /// it lands. Static so tests can shorten it.
  static Duration uploadWaitTimeout = const Duration(seconds: 20);

  /// Where the captured audio lands while recording.
  String? _capturePath;

  String get formattedElapsed {
    final m = (elapsedSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Native label of the language the live transcript is using.
  String get activeLanguageLabel =>
      recordingLanguageLabel(_speech.activeRecordingLanguage);

  /// Completes after the next rendered frame — defers UI side effects that
  /// would otherwise run while the page is still building (onInit).
  Future<void> _waitForPostFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    return completer.future;
  }

  @override
  void onInit() {
    super.onInit();
    // Mirror the shared live-STT stream into this screen's transcript panel.
    _transcriptWorker = ever<String>(
      _speech.liveText,
      (text) => liveTranscript.value = text,
    );
    liveTranscript.value = '';
    // Notification buttons (Pause / Resume / Stop) come back here.
    _background.onAction = _onBackgroundAction;
    startRecording();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _transcriptWorker?.dispose();
    _background.onAction = null;
    _speech.allowBackgroundListening = false;
    _socket.allowBackgroundReconnect = false;
    unawaited(_background.stop());
    unawaited(_speech.stopListening());
    noteController.dispose();
    super.onClose();
  }

  void selectSurface(String value) {
    selectedSurface.value = value;
  }

  Future<void> startRecording() async {
    if (_started) return;
    _started = true;

    // The controller is created while the page is still building; showing the
    // language sheet synchronously here would insert an overlay mid-build
    // ("visitChildElements() called during build"). Wait one frame first.
    await _waitForPostFrame();

    // Ask which language to transcribe before the mic goes live; dismissing
    // keeps the current selection.
    await showRecordingLanguageSheet();

    isRecording.value = true;
    _startTicker();

    final result = await _recording.start(AppLocales.recording.liveMeeting.tr);
    if (result.success && (result.data?.id ?? '').isNotEmpty) {
      recordingId.value = result.data!.id;
    }

    _capturePath = await _newCapturePath();

    // Keep the mic + live transcript alive when the user switches apps (e.g.
    // joining the meeting in Zoom). The socket must also keep reconnecting: a
    // dropped connection would otherwise stop the transcript.
    _speech.allowBackgroundListening = true;
    _socket.allowBackgroundReconnect = true;
    await _background.start(title: AppLocales.recording.liveMeeting.tr);

    await _startLiveTranscript();
  }

  /// Handles a Pause / Resume / Stop tap on the recording notification.
  void _onBackgroundAction(String action) {
    switch (action) {
      case RecordingSessionService.actionPause:
        if (isRecording.value) {
          unawaited(pauseRecording());
        }
      case RecordingSessionService.actionResume:
        if (!isRecording.value && !isFinishing.value) {
          unawaited(resumeRecording());
        }
      case RecordingSessionService.actionStop:
        if (!isFinishing.value) {
          unawaited(finishRecording());
        }
    }
  }

  Future<void> toggleRecording() async {
    if (isFinishing.value) return;
    if (isRecording.value) {
      await pauseRecording();
    } else {
      await resumeRecording();
    }
  }

  /// Real length of the captured WAV in seconds (null when unavailable).
  /// 16-bit PCM mono at [AppConstants.speechSampleRate] → the byte rate is
  /// sampleRate × channels × 2; the 44-byte RIFF header is not audio.
  int? capturedAudioSeconds(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final dataBytes = file.lengthSync() - 44;
      if (dataBytes <= 0) return null;
      final bytesPerSecond =
          AppConstants.speechSampleRate * AppConstants.speechNumChannels * 2;
      return (dataBytes / bytesPerSecond).round().clamp(1, 24 * 3600);
    } catch (_) {
      return null;
    }
  }

  Future<void> pauseRecording() async {
    isRecording.value = false;
    _ticker?.cancel();
    // Release the mic while paused; everything captured so far is kept.
    await _speech.stopListening();
    isTranscriptLive.value = false;

    final id = recordingId.value;
    if (id != null && id.isNotEmpty) {
      await _recording.updateRecording(
        id,
        status: 'paused',
        // Report what's actually captured so far — the file, not the clock.
        durationSecs:
            capturedAudioSeconds(_capturePath) ?? elapsedSeconds.value,
      );
    }

    unawaited(_background.markPaused(formattedElapsed));
  }

  Future<void> resumeRecording() async {
    isRecording.value = true;
    _startTicker();

    final id = recordingId.value;
    if (id != null && id.isNotEmpty) {
      await _recording.updateRecording(id, status: 'recording');
    }

    unawaited(_background.markRunning(formattedElapsed));
    await _startLiveTranscript();
  }

  /// Opens the system file picker and stages the chosen file to ride along
  /// with the recording. The upload happens at finish, when the atom exists.
  Future<void> pickAttachment() async {
    try {
      final file = await FilePickerPlatform.instance.pickFile(
        type: FileType.any,
      );
      if (file == null) return;
      stageAttachment(path: file.path, name: file.name);
    } catch (error) {
      debugPrint('🎙️ [LiveActivity] attachment pick failed: $error');
      AppSnackbar.error(AppLocales.ai.filePickerFailed.tr);
    }
  }

  /// Stages a picked file — kept separate from [pickAttachment] so tests can
  /// stage files without the platform picker.
  void stageAttachment({String? path, required String name}) {
    if (path == null || path.isEmpty) {
      AppSnackbar.info('No file path available');
      return;
    }
    if (attachments.any((attachment) => attachment.path == path)) return;
    attachments.add(RecordingAttachment(path: path, name: name));
    AppSnackbar.info(AppLocales.ai.attachedFile.trParams({'name': name}));
  }

  void removeAttachment(RecordingAttachment attachment) {
    attachments.removeWhere((item) => item.path == attachment.path);
  }

  Future<void> finishRecording() async {
    if (isFinishing.value) return;
    isFinishing.value = true;
    _ticker?.cancel();

    try {
      // Best-effort teardown: every step is bounded so a stalled mic, socket
      // or OEM plugin can never wedge the finish (testers: "End does nothing,
      // can't exit"). On timeout the underlying step keeps running in the
      // background — only the wait ends.
      await _speech
          .stopListening()
          .timeout(teardownTimeout, onTimeout: () {});
      isTranscriptLive.value = false;
      // The session is over — drop the foreground service (and its
      // notification) now that the mic no longer needs background access.
      _speech.allowBackgroundListening = false;
      _socket.allowBackgroundReconnect = false;
      await _background.stop();
      // Closes the WAV so it can be uploaded.
      final audioPath = await _speech.finishCapture();
      // Report the file's real length, not the timer — background chunks can
      // be dropped, which made the atom show more time than the audio
      // actually has.
      final capturedSecs = capturedAudioSeconds(audioPath);

      final id = recordingId.value;
      if (id == null || id.isEmpty) {
        isFinishing.value = false;
        Get.closeAllSnackbars();
        Get.back();
        return;
      }

      final result = await _recording
          .finish(
            id,
            durationSecs: capturedSecs ?? elapsedSeconds.value,
            transcript: liveTranscript.value.trim(),
            note: noteController.text.trim(),
          )
          .timeout(const Duration(seconds: 60));
      if (result.success) {
        final atomId = result.data?.atomId ?? '';
        if (atomId.isNotEmpty) {
          if (audioPath != null) {
            // A slow upload must not hold the screen hostage — the atom
            // already exists, and the attach broadcasts when it lands so
            // atom details picks the audio up live.
            await _uploadAudio(
              atomId,
              audioPath,
            ).timeout(uploadWaitTimeout, onTimeout: () {});
          }
          if (attachments.isNotEmpty) {
            // Same bounded best-effort as the audio: the atom already
            // exists, so every staged file rides upload → attach and the
            // screen never waits forever on a slow connection.
            await _uploadAttachments(
              atomId,
              attachments.toList(),
            ).timeout(uploadWaitTimeout, onTimeout: () {});
          }
          // Ask which molecule the new atom belongs to — dismissing leaves it
          // uncategorized, and a failure here must never block the finish.
          try {
            final picked = await showMoleculePickerSheet();
            if (picked != null && picked.isNotEmpty) {
              await _home.setCategory(atomId: atomId, categoryId: picked);
              await Get.find<CategoryService>().refresh();
            }
          } catch (_) {}
          // Replace the finished recording sheet so Back lands on the screen
          // the recording was started from, not on a dead recording session.
          AppRoutes.toAtomDetail(atomId: atomId, replace: true);
          return;
        }
        Get.closeAllSnackbars();
        Get.back();
      } else {
        AppSnackbar.error(result.error ?? result.message);
        isFinishing.value = false;
      }
    } catch (error) {
      // Anything unexpected (a timed-out finish call, a platform error) must
      // leave the screen usable — the user can retry or leave normally.
      debugPrint('🎙️ [LiveActivity] finish failed: $error');
      AppSnackbar.error(AppLocales.recording.finishFailed.tr);
      isFinishing.value = false;
    }
  }

  /// Uploads the captured audio and attaches it to the finished atom, so the
  /// recording is playable from atom details.
  Future<void> _uploadAudio(String atomId, String path) async {
    try {
      // The asset keeps the FILE's real length, not the wall-clock timer: the
      // file is what plays back, and the timer runs past it when background
      // chunks are dropped. Same rule as the atom's duration at finish.
      final upload = await _media.uploadImage(
        filePath: path,
        filename: 'recording.wav',
        type: AssetKeys.typeAudio,
        folder: 'recordings',
        durationSecs: capturedAudioSeconds(path) ?? elapsedSeconds.value,
        showLoading: false,
      );

      final assetId = upload.data?.id ?? '';
      if (!upload.success || assetId.isEmpty) {
        debugPrint(
          '🎙️ [LiveActivity] audio upload failed: ${upload.error ?? upload.message}',
        );
        AppSnackbar.error(upload.error ?? upload.message);
        return;
      }

      final attach = await _home.attachAsset(atomId: atomId, assetId: assetId);
      if (!attach.success) {
        debugPrint('🎙️ [LiveActivity] audio attach failed: ${attach.error}');
        AppSnackbar.error(attach.error ?? attach.message);
        return;
      }

      // The atom has the audio now — the temp file is no longer needed.
      try {
        await File(path).delete();
      } catch (_) {
        // Best effort; the OS clears its temp directory eventually.
      }
    } catch (error) {
      debugPrint('🎙️ [LiveActivity] audio upload error: $error');
    }
  }

  /// Uploads every staged attachment and attaches it to the finished atom —
  /// the same upload → attach rail the recording audio rides. One failure
  /// never stops the rest.
  Future<void> _uploadAttachments(
    String atomId,
    List<RecordingAttachment> items,
  ) async {
    for (final item in items) {
      try {
        final upload = await _media.uploadImage(
          filePath: item.path,
          filename: item.name,
          type: AssetKeys.typeAttachment,
          folder: 'atoms',
          showLoading: false,
        );

        final assetId = upload.data?.id ?? '';
        if (!upload.success || assetId.isEmpty) {
          debugPrint(
            '🎙️ [LiveActivity] attachment upload failed: ${upload.error ?? upload.message}',
          );
          AppSnackbar.error(upload.error ?? upload.message);
          continue;
        }

        final attach = await _home.attachAsset(
          atomId: atomId,
          assetId: assetId,
        );
        if (!attach.success) {
          debugPrint(
            '🎙️ [LiveActivity] attachment attach failed: ${attach.error}',
          );
          AppSnackbar.error(attach.error ?? attach.message);
        }
      } catch (error) {
        debugPrint('🎙️ [LiveActivity] attachment upload error: $error');
      }
    }
  }

  Future<String> _newCapturePath() async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/atomicos_recording_$stamp.wav';
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
      unawaited(_background.markRunning(formattedElapsed));
    });
  }

  /// Starts (or resumes) live speech-to-text, seeding it with what has already
  /// been transcribed so the text keeps appending across pauses. The same mic
  /// stream is written to [_capturePath] so the recording keeps its audio.
  Future<void> _startLiveTranscript() async {
    final result = await _speech.startListening(
      seed: liveTranscript.value,
      capturePath: _capturePath,
      allowOfflineCapture: true,
    );
    isTranscriptLive.value =
        result == ESpeechListenResult.started ||
        result == ESpeechListenResult.alreadyListening;
    transcriptNotice.value = isTranscriptLive.value
        ? null
        : _noticeFor(result);
  }

  String? _noticeFor(ESpeechListenResult result) {
    switch (result) {
      case ESpeechListenResult.disconnected:
        return AppLocales.recording.transcriptOffline.tr;
      case ESpeechListenResult.permissionDenied:
        return AppLocales.recording.transcriptMicNeeded.tr;
      case ESpeechListenResult.capturedOffline:
        return AppLocales.recording.transcriptOfflineRecording.tr;
      case ESpeechListenResult.alreadyListening:
        return null;
      case ESpeechListenResult.started:
        return null;
      case ESpeechListenResult.failed:
        return AppLocales.recording.transcriptUnavailable.tr;
    }
  }
}
