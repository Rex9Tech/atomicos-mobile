// lib/modules/setting/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/config/config.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/google_calendar.service.dart';

import '../../auth/auth.dart';
import '../../profile/profile.dart';
import '../setting.dart';

class SettingPage extends GetView<SettingController> {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return AppPage(
      title: AppLocales.setting.settings.tr,
      showBackButton: true,
      showTimeZone: false,
      child: ListView(
        padding: EdgeInsets.all(Design.spacing.lg),
        children: [
          // Theme Section
          _buildSectionHeader(context, AppLocales.setting.theme.tr),
          _buildThemeTile(context),

          SizedBox(height: Design.spacing.xxl),

          // Language Section
          _buildSectionHeader(context, AppLocales.setting.language.tr),
          _buildLanguageTile(context),

          SizedBox(height: Design.spacing.xxl),

          // Integrations Section — Google Calendar connect/status + meeting
          // alerts (on/off + how early the reminder fires).
          _buildSectionHeader(context, AppLocales.setting.integrations.tr),
          _buildGoogleCalendarTile(context),

          SizedBox(height: Design.spacing.sm),

          _buildMeetingAlertsCard(context),

          SizedBox(height: Design.spacing.xxl),

          // Subscription Section — plans & MyanMyanPay (MMQR) checkout
          _buildSectionHeader(context, AppLocales.payment.plansPricing.tr),
          _buildPlansTile(context),

          SizedBox(height: Design.spacing.xxl),

          // Account Section
          _buildSectionHeader(context, AppLocales.setting.account.tr),
          _buildAccountTile(context, authController),

          SizedBox(height: Design.spacing.xxl),

          // Categories (personal — every user manages their own)
          _buildSectionHeader(context, AppLocales.category.title.tr),
          _buildCategoriesTile(context),

          SizedBox(height: Design.spacing.xxl),

          // Feedback Section
          _buildSectionHeader(context, AppLocales.feedback.title.tr),
          _buildFeedbackTile(context),

          SizedBox(height: Design.spacing.xxl),

          // App Info Section
          _buildSectionHeader(context, AppLocales.setting.appInfo.tr),
          _buildAppInfoTile(context),
        ],
      ),
    );
  }

  Widget _buildFeedbackTile(BuildContext context) {
    return AppCard(
      borderRadius: Design.spacing.radiusLarge,
      padding: EdgeInsets.zero,
      child: AppListTile(
        leading: Icon(Icons.feedback_outlined, color: context.colors.primary),
        title: Text(AppLocales.feedback.title.tr),
        subtitle: Text(AppLocales.feedback.description.tr),
        trailing:
            Icon(Design.icons.rightArrow, color: context.colors.textSecondary),
        onTap: () => Get.toNamed(AppRoutes.feedback),
      ),
    );
  }

  /// Plans & Pricing — product list + MyanMyanPay (MMQR) / store checkout.
  Widget _buildPlansTile(BuildContext context) {
    return AppCard(
      borderRadius: Design.spacing.radiusLarge,
      padding: EdgeInsets.zero,
      child: AppListTile(
        leading: Icon(
          Icons.workspace_premium_outlined,
          color: context.colors.primary,
        ),
        title: Text(AppLocales.payment.plansPricing.tr),
        subtitle: Text(AppLocales.payment.choosePlanSub.tr),
        trailing:
            Icon(Design.icons.rightArrow, color: context.colors.textSecondary),
        onTap: AppRoutes.toPayment,
      ),
    );
  }

  /// Admin-only entry: create/remove the categories users attach to atoms.
  Widget _buildCategoriesTile(BuildContext context) {
    return AppCard(
      borderRadius: Design.spacing.radiusLarge,
      padding: EdgeInsets.zero,
      child: AppListTile(
        leading: Icon(Design.icons.category, color: context.colors.primary),
        title: Text(AppLocales.category.manage.tr),
        subtitle: Text(AppLocales.category.manageSub.tr),
        trailing:
            Icon(Design.icons.rightArrow, color: context.colors.textSecondary),
        onTap: AppRoutes.toAdminCategories,
      ),
    );
  }

  /// Google Calendar connect — popup → store when the app is missing; once
  /// connected the tile wears a status pill and opens the manage actions.
  Widget _buildGoogleCalendarTile(BuildContext context) {
    final calendar = Get.find<GoogleCalendarService>();

    return Obx(() {
      final connected = calendar.connected.value;

      return AppCard(
        borderRadius: Design.spacing.radiusLarge,
        padding: EdgeInsets.zero,
        child: AppListTile(
          leading: Icon(Design.icons.calendar, color: context.colors.primary),
          title: Text(AppLocales.calendar.connectTitle.tr),
          subtitle: Text(
            connected
                ? AppLocales.calendar.connectedSub.tr
                : AppLocales.calendar.connectSubtitle.tr,
          ),
          trailing: connected
              ? _buildConnectedBadge(context)
              : Icon(
                  Design.icons.rightArrow,
                  color: context.colors.textSecondary,
                ),
          onTap: () => connected
              ? _showCalendarManageDialog(context, calendar)
              : controller.connectGoogleCalendar(context),
        ),
      );
    });
  }

  /// Green status pill shown once Google Calendar is connected.
  Widget _buildConnectedBadge(BuildContext context) {
    final success = Design.colors.success;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Design.spacing.sm,
        vertical: Design.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppLocales.calendar.connected.tr,
        style: context.typo.labelMedium.copyWith(
          color: success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Connected tile actions: open Google Calendar, or disconnect (which also
  /// cancels the armed meeting alerts).
  Future<void> _showCalendarManageDialog(
    BuildContext context,
    GoogleCalendarService calendar,
  ) async {
    final action = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        ),
        title: Text(
          AppLocales.calendar.appTitle.tr,
          style: context.typo.headline4.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(AppLocales.calendar.connectedSub.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocales.common.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'disconnect'),
            child: Text(
              AppLocales.calendar.disconnect.tr,
              style: TextStyle(color: context.colors.error),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'open'),
            child: Text(AppLocales.calendar.openCalendarApp.tr),
          ),
        ],
      ),
    );

    switch (action) {
      case 'open':
        await calendar.openApp();
      case 'disconnect':
        await calendar.disconnect();
        AppSnackbar.success(AppLocales.calendar.disconnected.tr);
    }
  }

  /// Meeting alerts — on/off plus how early the reminder fires.
  Widget _buildMeetingAlertsCard(BuildContext context) {
    return AppCard(
      borderRadius: Design.spacing.radiusLarge,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Obx(
            () => AppListTile(
              leading: Icon(
                Icons.notifications_active_outlined,
                color: context.colors.primary,
              ),
              title: Text(AppLocales.calendar.alertsTitle.tr),
              subtitle: Text(AppLocales.calendar.alertsSub.tr),
              trailing: AppToggle(
                value: controller.meetingAlertsEnabled.value,
                onChanged: controller.setMeetingAlertsEnabled,
                activeColor: context.colors.primary,
              ),
              onTap: () => controller.setMeetingAlertsEnabled(
                !controller.meetingAlertsEnabled.value,
              ),
            ),
          ),
          Divider(
            color: context.colors.divider,
            indent: Design.spacing.lg,
            endIndent: Design.spacing.lg,
          ),
          Obx(
            () => AppListTile(
              leading: Icon(
                Icons.schedule_outlined,
                color: context.colors.textSecondary,
              ),
              title: Text(AppLocales.calendar.alertsLead.tr),
              subtitle: Text(
                AppLocales.calendar.leadMinutes.trParams({
                  'count': '${controller.meetingAlertLeadMinutes.value}',
                }),
              ),
              trailing: PopupMenuButton<int>(
                icon: Icon(
                  Design.icons.downArrow,
                  color: context.colors.textSecondary,
                ),
                onSelected: controller.setMeetingAlertLeadMinutes,
                itemBuilder: (context) => SettingController
                    .meetingAlertLeadOptions
                    .map(
                      (minutes) => PopupMenuItem<int>(
                        value: minutes,
                        child: Text(
                          AppLocales.calendar.leadMinutes.trParams({
                            'count': '$minutes',
                          }),
                          style: context.typo.bodyMedium.copyWith(
                            color:
                                controller.meetingAlertLeadMinutes.value ==
                                    minutes
                                ? context.colors.primary
                                : context.colors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: Design.spacing.sm,
        bottom: Design.spacing.md,
        top: Design.spacing.md,
      ),
      child: Text(
        title.toUpperCase(),
        style: context.typo.labelMedium.copyWith(
          color: context.colors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    return Obx(
      () => AppCard(
        borderRadius: Design.spacing.radiusLarge,
        padding: EdgeInsets.zero,
        child: AppListTile(
          leading: Icon(controller.themeIcon, color: context.colors.primary),
          title: Text(AppLocales.setting.theme.tr),
          subtitle: Text(controller.themeLabel),
          trailing: AppToggle(
            value: controller.isDarkMode.value,
            onChanged: (_) => controller.toggleTheme(),
            activeColor: context.colors.primary,
          ),
          onTap: controller.toggleTheme,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    return AppCard(
      borderRadius: Design.spacing.radiusLarge,
      padding: EdgeInsets.zero,
      child: AppListTile(
        leading: _buildFlagIcon(context),
        title: Text(AppLocales.setting.language.tr),
        subtitle: Obx(() => Text(controller.currentLanguageName)),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Design.icons.downArrow,
            color: context.colors.textSecondary,
          ),
          onSelected: controller.changeLocale,
          itemBuilder: (context) => controller.supportedLocales
              .map(
                (entry) => PopupMenuItem<String>(
                  value: entry.key,
                  child: Obx(
                    () => Row(
                      children: [
                        _buildFlagIcon(context, locale: entry.key),
                        SizedBox(width: Design.spacing.sm),
                        Text(
                          entry.value,
                          style: context.typo.bodyMedium.copyWith(
                            color: controller.isLocale(entry.key)
                                ? context.colors.primary
                                : context.colors.textPrimary,
                          ),
                        ),
                        if (controller.isLocale(entry.key))
                          Icon(
                            Design.icons.check,
                            size: Design.spacing.iconSmall,
                            color: context.colors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFlagIcon(BuildContext context, {String? locale}) {
    final String code = locale ?? controller.localeCode.value;
    return Text(
      FlagHelper.getEmoji(code),
      style: TextStyle(fontSize: Design.spacing.iconLarge),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    AuthController authController,
  ) {
    return AppCard(
      borderRadius: Design.spacing.radiusLarge,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Obx(
            () => AppListTile(
              leading: AppAvatar(
                url: authController.currentUser.value?.photo,
                name:
                    authController.currentUser.value?.name ??
                    authController.currentUser.value?.username ??
                    authController.currentUser.value?.email,
                radius: Design.spacing.avatarRadius / 2,
              ),
              title: Text(
                authController.currentUser.value?.name ??
                    authController.currentUser.value?.username ??
                    AppLocales.setting.account.tr,
              ),
              subtitle: Text(
                authController.currentUser.value?.email ??
                    AppLocales.common.loading.tr,
              ),
              trailing: Icon(
                Design.icons.rightArrow,
                color: context.colors.textSecondary,
              ),
              onTap: AppRoutes.toProfile,
            ),
          ),
          Divider(
            color: context.colors.divider,
            indent: Design.spacing.lg,
            endIndent: Design.spacing.lg,
          ),
          AppListTile(
            leading: Icon(Design.icons.logout, color: context.colors.error),
            title: Text(AppLocales.common.signOut.tr),
            isDestructive: true,
            onTap: () => _showLogoutDialog(context, authController),
          ),
          Divider(
            color: context.colors.divider,
            indent: Design.spacing.lg,
            endIndent: Design.spacing.lg,
          ),
          AppListTile(
            leading: Icon(Icons.delete_forever_outlined, color: context.colors.error),
            title: Text(AppLocales.user.deleteAccount.tr),
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoTile(BuildContext context) {
    return AppCard(
      borderRadius: Design.spacing.radiusLarge,
      padding: EdgeInsets.zero,
      child: AppListTile(
        leading: Icon(Design.icons.info, color: context.colors.textSecondary),
        title: Text(AppConfig.appName),
        subtitle: Obx(() => Text('v${controller.appVersion.value}')),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthController authController,
  ) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppLocales.common.signOut.tr,
      message: AppLocales.setting.logoutConfirmation.tr,
      confirmLabel: AppLocales.common.signOut.tr,
      destructive: true,
    );
    if (confirmed) authController.signOut();
  }

  void _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppLocales.user.deleteConfirmTitle.tr,
      message: AppLocales.user.deleteConfirmMessage.trParams({
        'email': AppConfig.fromEmail,
      }),
      confirmLabel: AppLocales.user.deleteAccount.tr,
    );
    if (confirmed) {
      AppLoading.show();
      try {
        final profileService = Get.find<ProfileService>();
        final res = await profileService.discardCurrentUser();
        if (!res.success) {
          AppSnackbar.error(res.error ?? res.message);
          return;
        }
        AppSnackbar.success(AppLocales.user.deleteSuccess.tr);
        if (Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().signOut();
        }
      } catch (e, stk) {
        AppSnackbar.error(AppLocales.user.deleteFailed.tr, e: e, stk: stk);
      } finally {
        AppLoading.hide();
      }
    }
  }
}

