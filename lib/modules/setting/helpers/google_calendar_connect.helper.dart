// lib/modules/setting/helpers/google_calendar_connect.helper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';

import '../../../locales/app_translations.dart';
import '../../../services/google_calendar.service.dart';
import '../../../services/meeting_reminder.service.dart';

/// Shows the "Connect Google Calendar" popup and runs the connect flow when
/// the user confirms. Shared by Settings → Integrations and the post-login
/// prompt.
Future<void> promptGoogleCalendarConnect(BuildContext context) async {
  Get.addTranslations(AppTranslations().keys);
  final shouldConnect = await AppDialog.confirm(
    context: context,
    title: AppLocales.calendar.connectTitle.tr,
    message: AppLocales.calendar.connectMessage.tr,
    confirmLabel: AppLocales.calendar.connectAction.tr,
    cancelLabel: AppLocales.calendar.notNow.tr,
  );
  if (!shouldConnect) return;

  final result = await Get.find<GoogleCalendarService>().connect();
  switch (result) {
    case GoogleCalendarConnectResult.connected:
      AppSnackbar.success(
        AppLocales.calendar.connectDone.trParams({
          'count': '${Get.find<MeetingReminderService>().armedCount}',
        }),
      );
    case GoogleCalendarConnectResult.storeOpened:
      AppSnackbar.info(AppLocales.calendar.storeOpened.tr);
    case GoogleCalendarConnectResult.permissionDenied:
      AppSnackbar.error(AppLocales.calendar.permissionDenied.tr);
    case GoogleCalendarConnectResult.unsupported:
    case GoogleCalendarConnectResult.failed:
      AppSnackbar.error(AppLocales.calendar.connectFailed.tr);
  }
}
