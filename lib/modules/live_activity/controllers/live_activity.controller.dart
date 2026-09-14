import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../ai/services/recording.service.dart';

/// Drives the live recording sheet: the backend session record, the timer, and
/// the live transcript streamed from the microphone through [SpeechService].
class LiveActivityController extends GetxController {
  final RecordingService _recording = Get.find<RecordingService>();
  final SpeechService _speech = Get.find<SpeechService>();

  final RxString selectedSurface = 'Expanded'.obs;
  final RxBool isRecording = false.obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxnString recordingId = RxnString();
  final RxBool isFinishing = false.obs;
  final noteController = TextEditingController();

  /// Transcript text streamed live from the mic while recording.
  final RxString liveTranscript = ''.obs;

  /// Whether the live STT session is running right now.
  final RxBool isTranscriptLive = false.obs;

  /// Set when the live transcript cannot start (offline, no permission…).
  final RxnString transcriptNotice = RxnString();

  Timer? _ticker;
  Worker? _transcriptWorker;
  bool _started = false;

  String get formattedElapsed {
    final m = (elapsedSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
    startRecording();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _transcriptWorker?.dispose();
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
    isRecording.value = true;
    _startTicker();

    final result = await _recording.start('Live meeting');
    if (result.success && (result.data?.id ?? '').isNotEmpty) {
      recordingId.value = result.data!.id;
    }

    await _startLiveTranscript();
  }

  Future<void> toggleRecording() async {
    if (isFinishing.value) return;
    if (isRecording.value) {
      await pauseRecording();
    } else {
      await resumeRecording();
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
        durationSecs: elapsedSeconds.value,
      );
    }
  }

  Future<void> resumeRecording() async {
    isRecording.value = true;
    _startTicker();

    final id = recordingId.value;
    if (id != null && id.isNotEmpty) {
      await _recording.updateRecording(id, status: 'recording');
    }

    await _startLiveTranscript();
  }

  Future<void> finishRecording() async {
    if (isFinishing.value) return;
    isFinishing.value = true;
    _ticker?.cancel();
    await _speech.stopListening();
    isTranscriptLive.value = false;

    final id = recordingId.value;
    if (id == null || id.isEmpty) {
      isFinishing.value = false;
      Get.back();
      return;
    }

    final result = await _recording.finish(
      id,
      durationSecs: elapsedSeconds.value,
      transcript: liveTranscript.value.trim(),
      note: noteController.text.trim(),
    );
    if (result.success) {
      final atomId = result.data?.atomId ?? '';
      if (atomId.isNotEmpty) {
        AppRoutes.toAtomDetail(atomId: atomId);
        return;
      }
      Get.back();
    } else {
      AppSnackbar.error(result.error ?? result.message);
      isFinishing.value = false;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
    });
  }

  /// Starts (or resumes) live speech-to-text, seeding it with what has already
  /// been transcribed so the text keeps appending across pauses.
  Future<void> _startLiveTranscript() async {
    final result = await _speech.startListening(seed: liveTranscript.value);
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
        return 'Live transcript is offline — reconnect to stream it.';
      case ESpeechListenResult.permissionDenied:
        return 'Microphone permission is needed for the live transcript.';
      case ESpeechListenResult.alreadyListening:
        return null;
      case ESpeechListenResult.started:
        return null;
      case ESpeechListenResult.failed:
        return 'Live transcript is unavailable right now.';
    }
  }
}
