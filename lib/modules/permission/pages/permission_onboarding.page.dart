import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';

import '../controllers/permission_onboarding.controller.dart';

class PermissionOnboardingPage extends GetView<PermissionOnboardingController> {
  const PermissionOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppPage(
      backgroundColor: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(context),
          SizedBox(height: Design.spacing.lg),
          Text(
            AppLocales.permission.title.tr,
            style: context.typo.headline3.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: Design.spacing.xs),
          Text(
            AppLocales.permission.subtitle.tr,
            style: context.typo.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: Design.spacing.lg),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                children: [
                  _PermissionRow(
                    icon: Design.icons.micOutline,
                    title: AppLocales.ai.micPermissionTitle.tr,
                    message: AppLocales.ai.micPermissionMessage.tr,
                    granted: controller.micGranted.value,
                    onRequest: controller.requestMic,
                  ),
                  SizedBox(height: Design.spacing.md),
                  _PermissionRow(
                    icon: Design.icons.camera,
                    title: AppLocales.user.cameraPermissionTitle.tr,
                    message: AppLocales.user.cameraPermissionMessage.tr,
                    granted: controller.cameraGranted.value,
                    onRequest: controller.requestCamera,
                  ),
                  SizedBox(height: Design.spacing.md),
                  _PermissionRow(
                    icon: Design.icons.gallery,
                    title: AppLocales.user.photosPermissionTitle.tr,
                    message: AppLocales.user.photosPermissionMessage.tr,
                    granted: controller.photosGranted.value,
                    onRequest: controller.requestPhotos,
                  ),
                ],
              );
            }),
          ),
          SizedBox(height: Design.spacing.lg),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        GestureDetector(
          onTap: Get.back,
          child: Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: colors.neumo,
              gradient: colors.neumoGradient,
              shape: BoxShape.circle,
              boxShadow: colors.neumoShadowSoft,
            ),
            child: Icon(
              Design.icons.backArrow,
              size: Design.spacing.iconSmall,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.colors;

    return Obx(
      () => Row(
        children: [
          if (!controller.allGranted) ...[
            Expanded(
              child: GestureDetector(
                onTap: controller.isLoading.value
                    ? null
                    : controller.requestAll,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: Design.spacing.md),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      AppLocales.permission.grantAll.tr,
                      style: context.typo.labelLarge.copyWith(
                        color: colors.background,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: Design.spacing.md),
          ],
          Expanded(
            child: GestureDetector(
              onTap: Get.back,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: Design.spacing.md),
                decoration: BoxDecoration(
                  color: colors.neumo,
                  gradient: colors.neumoGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: colors.neumoShadowSoft,
                ),
                child: Center(
                  child: Text(
                    AppLocales.permission.done.tr,
                    style: context.typo.labelLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.message,
    required this.granted,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool granted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(Design.spacing.lg),
      decoration: BoxDecoration(
        color: colors.neumo,
        gradient: colors.neumoGradient,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        boxShadow: colors.neumoShadowSoft,
      ),
      child: Row(
        children: [
          Icon(icon, size: Design.spacing.iconMedium, color: colors.primary),
          SizedBox(width: Design.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Design.spacing.xs),
                Text(
                  message,
                  style: context.typo.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Design.spacing.sm),
          GestureDetector(
            onTap: granted ? null : onRequest,
            child: Icon(
              granted ? Design.icons.check : Design.icons.rightArrow,
              size: Design.spacing.iconSmall,
              color: granted ? colors.primary : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
