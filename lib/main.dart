// lib/main.dart
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rexone_mobile/config/config.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/services.dart';
import 'bindings/initial.binding.dart';
import 'locales/locales.dart';
import 'modules/media/media.dart';
import 'modules/setting/setting.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Telemetry & Error Listeners ("It works on my machine" killer)
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (originalOnError != null) {
      originalOnError(details);
    } else {
      FlutterError.presentError(details);
    }
    LogService.reportFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    LogService.reportPlatformError(error, stack);
    return true;
  };

  await dotenv.load(fileName: AppConfig.appEnv);
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ Firebase initializeApp skipped or failed: $e');
  }
  await GetStorage.init();
  await JustAudioBackground.init(
    androidNotificationChannelId: '${AppConfig.androidAppId}.audio',
    androidNotificationChannelName: AppConfig.appName,
    androidNotificationOngoing: true,
  );
  await AppInfo.init();
  InitialBinding().dependencies();

  // Best-effort boot steps. Each is time-boxed and guarded so a plugin that
  // stalls or fails can NEVER block the first frame — a wedged init here
  // white-screens the whole app (seen on MIUI: the media downloader's
  // foreground-service start never returning).
  Future<void> bootStep(
    String label,
    Future<void> Function() step, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final sw = Stopwatch()..start();
    try {
      await step().timeout(timeout);
      debugPrint('BOOT ok: $label (${sw.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('BOOT skip: $label after ${sw.elapsedMilliseconds}ms — $e');
    }
  }

  await bootStep(
    'push-notifications',
    () => Get.find<PushNotificationService>().initializePlatform(),
  );

  runApp(const MyApp());

  // Media stack initializes after the first frame — downloads only start
  // from user actions, so nothing needs it earlier.
  await bootStep(
    'media-download-notifications',
    () => Get.find<MediaDownloadNotificationService>().initialize(),
  );
  await bootStep(
    'media-downloader',
    () => Get.find<MediaDownloadService>().initializeDownloader(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = Get.find<AnalyticsService>();

    return GetBuilder<SettingController>(
      builder: (settings) => ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => GetMaterialApp(
          title: AppConfig.appName,
          theme: Design.theme.light,
          darkTheme: Design.theme.dark,
          themeMode: settings.themeMode,
          translations: AppTranslations(),
          locale: settings.locale,
          fallbackLocale: const Locale('en', 'US'),
          localizationsDelegates: AppLocalizations.delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.pages,
          unknownRoute: AppRoutes.notFound,
          navigatorObservers: [analytics.observer, MiniPlayerRouteObserver()],
          builder: (context, child) {
            return Overlay.wrap(
              child: AppNetworkBanner(
                child: AppMiniPlayerHost(
                  child: AppLoading.builder(context, child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
