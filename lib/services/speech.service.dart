// lib/services/speech.service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:record/record.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/api.service.dart';
import 'package:rexone_mobile/services/permission.service.dart';
import 'package:rexone_mobile/services/socket.service.dart';

/// Shared live STT + TTS client. Any controller can `Get.find<SpeechService>()`.
///
/// Owns the microphone, SpeechLiveChannel PCM stream, TTS HTTP queue, and
/// URL playback. Feature controllers keep their own text fields and message UI.
class SpeechService extends GetxService with WidgetsBindingObserver {
  late final ApiService _api;
  late final SocketService _socket;
  late final PermissionService _permissions;
  final AudioRecorder _recorder = AudioRecorder();
  AudioPlayer? _player;

  final RxBool isListening = false.obs;
  final RxDouble voiceLevel = 0.0.obs;
  final RxBool isPlaying = false.obs;
  final RxString liveText = ''.obs;

  /// How long to keep the live-STT subscription open after asking the backend
  /// to stop, so the final phrase is not lost.
  static const Duration _finalPhraseGrace = Duration(milliseconds: 1800);

  // ===== Audio capture =====
  // The mic stream is written to a WAV file while it is being forwarded to the
  // live STT socket, so a recording keeps its audio too.
  RandomAccessFile? _captureFile;
  String? _capturePath;
  int _captureBytes = 0;
  bool _captureOnly = false;

  bool _isStartingListen = false;
  bool _isTearingDown = false;
  bool _speechSubscribed = false;
  int _listenEpoch = 0;
  String _committedText = '';
  String _partialText = '';
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<Uint8List>? _pcmSub;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);

  /// Set by [AudioPlayerService] so TTS can take the single native player.
  Future<void> Function()? beforeTtsPlayback;

  bool get isListenSessionActive =>
      isListening.value || _speechSubscribed || _isStartingListen;

  bool get isBusy => isListenSessionActive || isPlaying.value;

  /// While true, an active recording keeps the mic and the live-STT stream
  /// running when the app moves to the background. Set by the recording
  /// session, which also runs the foreground service Android requires.
  bool allowBackgroundListening = false;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
    _socket = Get.find<SocketService>();
    _permissions = Get.find<PermissionService>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // A recording owns the mic: the foreground service keeps it permitted in
      // the background, so the stream (and live transcript) must keep running.
      final keepAlive =
          allowBackgroundListening && (isListening.value || _speechSubscribed);
      if (keepAlive) {
        debugPrint(
          '🎤 [SpeechService] backgrounded mid-recording — keeping the mic alive',
        );
        return;
      }

      if (isListening.value || _speechSubscribed) {
        unawaited(stopListening());
      }
      if (isPlaying.value) {
        unawaited(stopPlayback());
      }
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(stopListening());
    unawaited(finishCapture());
    unawaited(stopPlayback());
    unawaited(_recorder.dispose());
    super.onClose();
  }

  // ============================================================
  // TTS (TEXT-TO-SPEECH) HTTP
  // ============================================================

  /// Queues background TTS synthesis for an existing chat message.
  Future<ApiResponse<Map<String, dynamic>>> textToSpeech(
    String messageId, {
    bool showLoading = false,
  }) async {
    final response = await _api.post(ServerRoutes.textToSpeech, {
      SpeechKeys.messageId: messageId,
    }, showLoading: showLoading);
    return _api.parseRecord<Map<String, dynamic>>(response);
  }

  // ============================================================
  // STT (SPEECH-TO-TEXT) HTTP
  // ============================================================

  /// Transcribes recorded audio bytes synchronously using `/v1/speech/stt`.
  Future<ApiResponse<String>> speechToTextFromFile(
    Uint8List audioBytes, {
    String filename = 'audio.wav',
    bool showLoading = true,
  }) async {
    final form = FormData({
      SpeechKeys.audio: MultipartFile(
        audioBytes,
        filename: filename,
        contentType: 'audio/wav',
      ),
    });
    final response = await _api.postMultipart(
      ServerRoutes.speechToText,
      form,
      showLoading: showLoading,
    );
    return _api.parseRecord<String>(
      response,
      (json) => json[SpeechKeys.text]?.toString() ?? '',
    );
  }

  /// Transcribes remote audio from a URL synchronously using `/v1/speech/stt`.
  Future<ApiResponse<String>> speechToTextFromUrl(
    String audioUrl, {
    bool showLoading = true,
  }) async {
    final response = await _api.post(ServerRoutes.speechToText, {
      SpeechKeys.audioUrl: audioUrl,
    }, showLoading: showLoading);
    return _api.parseRecord<String>(
      response,
      (json) => json[SpeechKeys.text]?.toString() ?? '',
    );
  }

  // ============================================================
  // TTS PLAYBACK
  // ============================================================
  Future<void> playUrl(String url) async {
    await beforeTtsPlayback?.call();
    await stopPlayback();
    isPlaying.value = true;
    try {
      final player = _player ??= AudioPlayer();
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: SpeechKeys.ttsMediaId,
            title: AppLocales.ai.title.tr,
          ),
        ),
      );
      _playerStateSub?.cancel();
      _playerStateSub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          unawaited(stopPlayback());
        }
      });
      await player.play();
    } catch (_) {
      isPlaying.value = false;
      rethrow;
    }
  }

  Future<void> stopPlayback() async {
    _playerStateSub?.cancel();
    _playerStateSub = null;
    await _player?.stop();
    await _player?.dispose();
    _player = null;
    isPlaying.value = false;
  }

  // ============================================================
  // LIVE STT
  // ============================================================
  Future<ESpeechListenResult> startListening({
    String seed = '',
    String? capturePath,
    bool allowOfflineCapture = false,
  }) async {
    if (isListening.value || _isStartingListen) {
      return ESpeechListenResult.alreadyListening;
    }

    final canStream = _socket.isConnected.value;
    final wantsCapture = capturePath != null && capturePath.isNotEmpty;

    // Capture-only still makes sense offline: the audio is kept for a later
    // transcription, only the live text is lost.
    if (!canStream && !(wantsCapture && allowOfflineCapture)) {
      return ESpeechListenResult.disconnected;
    }

    if (!await _permissions.requestMicrophone() ||
        !await _recorder.hasPermission()) {
      return ESpeechListenResult.permissionDenied;
    }

    await stopPlayback();

    _isStartingListen = true;
    final epoch = ++_listenEpoch;
    try {
      _committedText = seed;
      _partialText = '';
      liveText.value = seed;
      _captureOnly = !canStream;

      if (canStream) {
        final subscribed = await _socket.subscribe(SpeechKeys.channel);
        if (epoch != _listenEpoch) {
          if (subscribed) {
            _socket.perform(SpeechKeys.channel, SpeechKeys.stop);
            _socket.unsubscribe(SpeechKeys.channel);
          }
          return ESpeechListenResult.failed;
        }
        if (!subscribed) {
          return ESpeechListenResult.disconnected;
        }
        _speechSubscribed = true;
      }

      if (wantsCapture) {
        await _openCapture(capturePath);
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: AppConstants.speechSampleRate,
          numChannels: AppConstants.speechNumChannels,
          streamBufferSize: AppConstants.speechChunkBytes,
          // The default (pause) stops the mic whenever another app takes audio
          // focus — joining the meeting in Zoom, media playback, a call. A
          // recorder must keep capturing through that.
          audioInterruption: AudioInterruptionMode.none,
        ),
      );
      if (epoch != _listenEpoch) {
        try {
          if (await _recorder.isRecording()) {
            await _recorder.stop();
          }
        } catch (e) {
          debugPrint('🎤 [SpeechService] Recorder stop error: $e');
        }
        return ESpeechListenResult.failed;
      }

      isListening.value = true;
      voiceLevel.value = 0;

      _pcmSub = stream.listen(
        _onPcmChunk,
        onError: (Object e) {
          debugPrint('🎤 [SpeechService] PCM stream error: $e');
          unawaited(stopListening());
        },
      );

      await _amplitudeSub?.cancel();
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amplitude) {
            voiceLevel.value = _normalizeAmplitude(amplitude.current);
          });

      await _connSub?.cancel();
      if (canStream) {
        _connSub = _socket.isConnected.listen((connected) {
          if (connected) {
            // Socket is back — re-attach the live STT session without touching
            // the mic, so the transcript resumes where it left off.
            unawaited(_reattachSpeechChannel());
            return;
          }

          if (!(isListening.value || _speechSubscribed)) return;

          if (allowBackgroundListening) {
            // Recording: keep the mic (and the audio capture) running and let
            // the channel re-attach on reconnect instead of tearing the whole
            // session down.
            _speechSubscribed = false;
            debugPrint(
              '🎤 [SpeechService] socket dropped — mic kept, STT will re-attach',
            );
            return;
          }

          unawaited(stopListening());
        });
      }

      return _captureOnly
          ? ESpeechListenResult.capturedOffline
          : ESpeechListenResult.started;
    } catch (e) {
      debugPrint('🎤 [SpeechService] Error starting live listen: $e');
      await stopListening();
      return ESpeechListenResult.failed;
    } finally {
      _isStartingListen = false;
    }
  }

  Future<void> stopListening() async {
    if (!isListening.value && !_speechSubscribed && !_isStartingListen) {
      return;
    }
    if (_isTearingDown) return;
    _isTearingDown = true;
    _listenEpoch++;
    try {
      await _pcmSub?.cancel();
      _pcmSub = null;
      await _amplitudeSub?.cancel();
      _amplitudeSub = null;
      await _connSub?.cancel();
      _connSub = null;

      if (_pcmBuffer.isNotEmpty) {
        _flushPcm();
      }
      _pcmBuffer.clear();

      try {
        if (await _recorder.isRecording()) {
          await _recorder.stop();
        }
      } catch (e) {
        debugPrint('🎤 [SpeechService] Teardown recorder stop error: $e');
      }

      if (_speechSubscribed) {
        _socket.perform(SpeechKeys.channel, SpeechKeys.stop);
        // The backend keeps the Azure socket alive briefly so the turn's
        // final phrase — proper casing and punctuation — still reaches us.
        await Future<void>.delayed(_finalPhraseGrace);
        _socket.unsubscribe(SpeechKeys.channel);
        _speechSubscribed = false;
      }

      isListening.value = false;
      voiceLevel.value = 0;
      _committedText = liveText.value;
      _partialText = '';
    } finally {
      _isTearingDown = false;
    }
  }

  /// Called by [SocketController] for SpeechLiveChannel partial/final/error.
  void onSpeechEvent(SocketMessage event, ESpeechEventType eventType) {
    if (!_speechSubscribed && !isListening.value) return;

    switch (eventType) {
      case ESpeechEventType.partial:
        _partialText = _mergePartial(_partialText, event.message ?? '');
        liveText.value = _joinSpeech(_committedText, _partialText);
      case ESpeechEventType.finalPhrase:
        _committedText = _joinSpeech(_committedText, event.message ?? '');
        _partialText = '';
        liveText.value = _committedText;
      case ESpeechEventType.error:
        unawaited(stopListening());
      case ESpeechEventType.unknown:
        break;
    }
  }

  void _onPcmChunk(Uint8List chunk) {
    _writeCapture(chunk);
    if (_captureOnly) return;
    _pcmBuffer.add(chunk);
    if (_pcmBuffer.length >= AppConstants.speechChunkBytes) {
      _flushPcm();
    }
  }

  // ============================================================
  // AUDIO CAPTURE (WAV)
  // ============================================================

  /// Opens [path] for capture. Called on resume too — an already open file is
  /// kept, so one recording produces one continuous WAV.
  Future<void> _openCapture(String path) async {
    if (_captureFile != null) return;

    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      final handle = await file.open(mode: FileMode.write);
      handle.writeFromSync(_wavHeader(0));
      _captureFile = handle;
      _capturePath = path;
      _captureBytes = 0;
    } catch (error) {
      debugPrint('🎤 [SpeechService] capture open error: $error');
      _captureFile = null;
      _capturePath = null;
    }
  }

  void _writeCapture(Uint8List chunk) {
    final handle = _captureFile;
    if (handle == null) return;

    try {
      handle.writeFromSync(chunk);
      _captureBytes += chunk.length;
    } catch (error) {
      debugPrint('🎤 [SpeechService] capture write error: $error');
    }
  }

  /// Finalizes the captured WAV (real header, then close) and returns its path,
  /// or null when nothing was captured.
  Future<String?> finishCapture() async {
    final handle = _captureFile;
    final path = _capturePath;
    final bytes = _captureBytes;
    _captureFile = null;
    _capturePath = null;
    _captureBytes = 0;

    if (handle == null || path == null) return null;

    try {
      if (bytes > 0) {
        handle.setPositionSync(0);
        handle.writeFromSync(_wavHeader(bytes));
      }
      await handle.flush();
      await handle.close();
    } catch (error) {
      debugPrint('🎤 [SpeechService] capture close error: $error');
      return null;
    }

    return bytes > 0 ? path : null;
  }

  /// Minimal 44-byte PCM WAV header for the captured stream format.
  Uint8List _wavHeader(int dataBytes) {
    const channels = AppConstants.speechNumChannels;
    const sampleRate = AppConstants.speechSampleRate;
    const bitsPerSample = 16;
    const blockAlign = channels * bitsPerSample ~/ 8;
    const byteRate = sampleRate * blockAlign;

    final header = BytesBuilder();
    void ascii(String value) => header.add(value.codeUnits);
    void u32(int value) => header.add([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
    void u16(int value) => header.add([value & 0xFF, (value >> 8) & 0xFF]);

    ascii('RIFF');
    u32(36 + dataBytes);
    ascii('WAVE');
    ascii('fmt ');
    u32(16);
    u16(1);
    u16(channels);
    u32(sampleRate);
    u32(byteRate);
    u16(blockAlign);
    u16(bitsPerSample);
    ascii('data');
    u32(dataBytes);

    return header.toBytes();
  }

  /// Re-attaches the live STT channel after a reconnect, leaving the mic (and
  /// the WAV capture) untouched. The backend opens a fresh recognition session
  /// for the new subscription; the text accumulated so far is kept client-side.
  Future<void> _reattachSpeechChannel() async {
    if (!isListening.value || _speechSubscribed) return;
    if (!_socket.isConnected.value) return;

    final epoch = _listenEpoch;
    final subscribed = await _socket.subscribe(SpeechKeys.channel);
    if (epoch != _listenEpoch) {
      if (subscribed) {
        _socket.perform(SpeechKeys.channel, SpeechKeys.stop);
        _socket.unsubscribe(SpeechKeys.channel);
      }
      return;
    }

    if (subscribed) {
      _speechSubscribed = true;
      debugPrint('🎤 [SpeechService] live STT re-attached after reconnect');
    }
  }

  void _flushPcm() {
    if (_pcmBuffer.isEmpty) return;
    if (!_speechSubscribed) {
      // Detached (socket dropped / reconnecting): drop this audio instead of
      // buffering it up — the WAV capture still has it.
      _pcmBuffer.clear();
      return;
    }
    final bytes = _pcmBuffer.takeBytes();
    if (bytes.isEmpty) return;
    _socket.perform(SpeechKeys.channel, SpeechKeys.audio, {
      SpeechKeys.chunk: base64Encode(bytes),
    });
  }

  String _joinSpeech(String committed, String incoming) {
    final next = incoming.trim();
    if (next.isEmpty) return committed;
    if (committed.isEmpty) return next;
    if (committed.endsWith(' ') || committed.endsWith('\n')) {
      return '$committed$next';
    }
    return '$committed $next';
  }

  String _mergePartial(String current, String incoming) {
    final next = incoming.trim();
    if (next.isEmpty) return current;
    if (current.isEmpty) return next;
    final currentLower = current.toLowerCase();
    final nextLower = next.toLowerCase();
    if (nextLower.startsWith(currentLower) ||
        currentLower.startsWith(nextLower)) {
      return next;
    }
    return _joinSpeech(current, next);
  }

  double _normalizeAmplitude(double db) {
    return ((db + 50) / 50).clamp(0.0, 1.0);
  }
}
