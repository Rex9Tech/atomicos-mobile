// lib/services/recording_session.service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';

/// Keeps a recording alive while the app is in the background.
///
/// Android only grants microphone access to a backgrounded app when it runs a
/// foreground service of type `microphone`, so one is started for the duration
/// of a recording. Its notification mirrors the recording state and carries
/// Pause/Resume/Stop buttons — those taps happen in the service isolate and are
/// forwarded to the main isolate through [onAction].
class RecordingSessionService extends GetxService {
  static const String actionPause = 'recording_pause';
  static const String actionResume = 'recording_resume';
  static const String actionStop = 'recording_stop';

  static const int _serviceId = 4201;

  bool _initialized = false;
  bool _active = false;

  /// Bumped on every start/stop so a slow start cannot resurrect a session
  /// that has already been stopped.
  int _generation = 0;

  /// Invoked on the main isolate when a notification button is tapped.
  void Function(String action)? onAction;

  bool get isActive => _active;

  /// Starts the foreground service so the mic (and the live transcript stream)
  /// keep working when the user leaves the app.
  Future<void> start({required String title}) async {
    final generation = ++_generation;

    _initialize();
    await FlutterForegroundTask.requestNotificationPermission();

    FlutterForegroundTask.addTaskDataCallback(_onTaskData);

    // Deliberately not awaited: on some OEM builds (MIUI) the plugin's own
    // start check waits out a long timeout even though the service is already
    // up, and the recording must not sit idle waiting for that verdict.
    unawaited(_startService(title, generation));
  }

  Future<void> _startService(String title, int generation) async {
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.microphone],
      notificationTitle: 'Recording — $title',
      notificationText: 'AtomicOS is recording and transcribing',
      notificationButtons: const [
        NotificationButton(id: actionPause, text: 'Pause'),
        NotificationButton(id: actionStop, text: 'Stop'),
      ],
      callback: recordingSessionCallback,
    );

    if (result is ServiceRequestFailure) {
      // Usually a false negative: the service is up, the check just timed out.
      debugPrint('🎙️ [RecordingSession] start reported: ${result.error}');
    }

    final running = await _confirmRunning();
    if (generation != _generation) {
      // Stopped while we were confirming — make sure it stays stopped.
      if (running) {
        try {
          await FlutterForegroundTask.stopService();
        } catch (_) {}
      }
      return;
    }

    _active = running;
    if (running) {
      unawaited(markRunning('00:00'));
    } else {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
      debugPrint('🎙️ [RecordingSession] service did not come up');
    }
  }

  /// Waits for the service to actually be up — OEM builds can be slow to
  /// report it, and a wrong "not running" state leaves the notification behind.
  Future<bool> _confirmRunning() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        if (await FlutterForegroundTask.isRunningService) return true;
      } catch (error) {
        debugPrint('🎙️ [RecordingSession] state check failed: $error');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return false;
  }

  /// Updates the notification (timer text and/or the Pause/Resume buttons).
  Future<void> updateStatus({
    String? title,
    String? text,
    List<NotificationButton>? buttons,
  }) async {
    if (!_active) return;
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
        notificationButtons: buttons,
      );
    } catch (error) {
      debugPrint('🎙️ [RecordingSession] update failed: $error');
    }
  }

  /// Updates the notification to the running state (Pause / Stop).
  Future<void> markRunning(String elapsed) => updateStatus(
    text: '$elapsed · recording',
    buttons: const [
      NotificationButton(id: actionPause, text: 'Pause'),
      NotificationButton(id: actionStop, text: 'Stop'),
    ],
  );

  /// Updates the notification to the paused state (Resume / Stop).
  Future<void> markPaused(String elapsed) => updateStatus(
    text: '$elapsed · paused',
    buttons: const [
      NotificationButton(id: actionResume, text: 'Resume'),
      NotificationButton(id: actionStop, text: 'Stop'),
    ],
  );

  /// Stops the service — the recording UI is gone or the session ended.
  /// Checks the real state first: a session whose start was misreported would
  /// otherwise leave the notification running forever.
  Future<void> stop() async {
    _generation++;
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _active = false;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (error) {
      debugPrint('🎙️ [RecordingSession] stop failed: $error');
    }
  }

  void _initialize() {
    if (_initialized) return;
    _initialized = true;

    // Lets the service isolate talk back to this one (button taps).
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'atomicos_recording',
        channelName: 'Recording',
        channelDescription:
            'Shown while AtomicOS is recording and transcribing in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  void _onTaskData(Object data) {
    final action = data.toString();
    debugPrint('🎙️ [RecordingSession] notification action: $action');
    onAction?.call(action);
  }
}

/// Entry point for the service isolate, required to be a top-level function.
@pragma('vm:entry-point')
void recordingSessionCallback() {
  FlutterForegroundTask.setTaskHandler(_RecordingSessionTaskHandler());
}

class _RecordingSessionTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    // Hand the tap to the main isolate, which owns the recording.
    FlutterForegroundTask.sendDataToMain(id);
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
