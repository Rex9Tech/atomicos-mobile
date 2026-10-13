// lib/services/media_upload_notification.service.dart
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/config/app.config.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/services/push_notification.service.dart';

/// Background-upload notification UX: a progress notification while a file
/// uploads (driven by the downloader) and a completion/failure notice after
/// the follow-up ran. Mirrors [MediaDownloadNotificationService].
class MediaUploadNotificationService extends GetxService {
  late final PushNotificationService _pushNotification;

  @override
  void onInit() {
    super.onInit();
    _pushNotification = Get.find<PushNotificationService>();
  }

  Future<void> initialize() async {
    FileDownloader().configureNotificationForGroup(
      MediaUploadConstants.uploadTaskGroup,
      running: TaskNotification(
        AppConfig.appName,
        '{displayName} · {progress}',
      ),
      complete: TaskNotification(
        AppConfig.appName,
        '{displayName}',
      ),
      error: TaskNotification(
        AppConfig.appName,
        '{displayName}',
      ),
      progressBar: true,
    );

    await _pushNotification.createAndroidChannel(
      AndroidNotificationChannel(
        MediaUploadConstants.notificationChannelId,
        AppLocales.media.uploadChannelName.tr,
        description: AppLocales.media.uploadChannelDescription.tr,
        importance: Importance.defaultImportance,
      ),
    );
  }

  Future<void> onUploadFinished({
    required String taskId,
    required String title,
    required bool success,
    String? errorMessage,
  }) async {
    if (!_pushNotification.isLocalNotificationsReady) return;

    final id = taskId.hashCode & 0x7fffffff;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        MediaUploadConstants.notificationChannelId,
        AppLocales.media.uploadChannelName.tr,
        channelDescription:
            AppLocales.media.uploadChannelDescription.tr,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    if (success) {
      await _pushNotification.showLocalNotification(
        id: id,
        title: AppConfig.appName,
        body: title.isEmpty
            ? AppLocales.media.uploadComplete.tr
            : AppLocales.media.uploadCompleteNamed.trParams({
                'title': title,
              }),
        details: details,
        payload: taskId,
      );
      return;
    }

    await _pushNotification.showLocalNotification(
      id: id,
      title: AppConfig.appName,
      body: errorMessage ?? AppLocales.media.uploadFailed.tr,
      details: details,
      payload: taskId,
    );
  }
}
