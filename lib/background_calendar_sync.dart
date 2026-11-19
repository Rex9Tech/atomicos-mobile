// lib/background_calendar_sync.dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:rexone_mobile/config/config.dart';
import 'package:rexone_mobile/locales/app_translations.dart';
import 'package:rexone_mobile/services/services.dart';

/// Headless entry point for the periodic background calendar sync
/// (`CalendarSyncWorker` boots a dedicated Flutter engine and runs this).
///
/// Re-arms meeting reminders without any UI, then reports completion through
/// the `atomicos/calendar_sync` channel so the worker can shut the engine
/// down. Kept deliberately minimal: no OneSignal, no Firebase, no Live
/// Activities — just storage + calendar + local notifications.
@pragma('vm:entry-point')
void calendarSyncMain() {
  WidgetsFlutterBinding.ensureInitialized();
  final done = MethodChannel('atomicos/calendar_sync');

  Future<void> finish() async {
    try {
      await done.invokeMethod<void>('done');
    } catch (error) {
      debugPrint('🗓️ [BackgroundSync] done signal failed: $error');
    }
  }

  runZonedGuarded(
    () async {
      try {
        try {
          await dotenv.load(fileName: AppConfig.appEnv);
        } catch (_) {
          // Best effort — the sync path does not depend on env values.
        }
        await GetStorage.init();
        Get.addTranslations(AppTranslations().keys);

        Get.put<StorageService>(StorageService());
        Get.put<DeviceCalendarService>(DeviceCalendarService());
        PushNotificationService.backgroundMode = true;
        Get.put<PushNotificationService>(PushNotificationService());
        await Get.find<PushNotificationService>().initializeLocalOnly();
        Get.put<MeetingReminderService>(MeetingReminderService());
        await Get.find<MeetingReminderService>().refresh();
        debugPrint('🗓️ [BackgroundSync] reminders refreshed');
      } catch (error) {
        debugPrint('🗓️ [BackgroundSync] failed: $error');
      } finally {
        await finish();
      }
    },
    (error, stack) async {
      debugPrint('🗓️ [BackgroundSync] zone error: $error');
      await finish();
    },
  );
}
