import 'dart:async';

import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';

import '../../ai/services/recording.service.dart';

class LiveActivityController extends GetxController {
  final RecordingService _recording = Get.find<RecordingService>();

  final RxString selectedSurface = 'Expanded'.obs;
  final RxBool isRecording = false.obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxnString recordingId = RxnString();
  final RxBool isFinishing = false.obs;

  Timer? _ticker;
  bool _started = false;

  String get formattedElapsed {
    final m = (elapsedSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void onInit() {
    super.onInit();
    startRecording();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  void selectSurface(String value) {
    selectedSurface.value = value;
  }

  Future<void> startRecording() async {
    if (_started) return;
    _started = true;
    isRecording.value = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
    });
    final result = await _recording.start('Live meeting');
    if (result.success && (result.data?.id ?? '').isNotEmpty) {
      recordingId.value = result.data!.id;
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

  Future<void> pauseRecording() async {
    isRecording.value = false;
    _ticker?.cancel();
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
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
    });
    final id = recordingId.value;
    if (id != null && id.isNotEmpty) {
      await _recording.updateRecording(id, status: 'recording');
    }
  }

  Future<void> finishRecording() async {
    if (isFinishing.value) return;
    isFinishing.value = true;
    _ticker?.cancel();

    final id = recordingId.value;
    if (id == null || id.isEmpty) {
      isFinishing.value = false;
      Get.back();
      return;
    }

    final result = await _recording.finish(id, durationSecs: elapsedSeconds.value);
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
}
