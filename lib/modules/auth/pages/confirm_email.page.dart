// lib/modules/auth/pages/confirm_email_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/routes.dart';

import '../auth.dart';

class ConfirmEmailPage extends GetView<AuthController> {
  const ConfirmEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>;

    controller.email.value = arguments['email'];

    final colors = context.colors;

    return AppPage(
      title: AppLocales.auth.confirmEmail.title.tr,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: Design.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: Design.spacing.xl),

              // Code was sent to your email
              Center(
                child: Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Design.icons.mailCheck,
                    size: Design.spacing.iconLarge,
                    color: colors.primary,
                  ),
                ),
              ),

              SizedBox(height: Design.spacing.lg),

              Text(
                AppLocales.auth.confirmEmail.heading.tr,
                style: context.typo.headline3,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: Design.spacing.xs),

              Obx(
                () => Text(
                  AppLocales.auth.confirmEmail.subtitle.trParams({
                    'email': controller.email.value,
                  }),
                  style: context.typo.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: Design.spacing.xxl),

              // Code entry
              AppGlassCard(
                radius: Design.spacing.radiusLarge,
                padding: EdgeInsets.all(Design.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppPasswordField(
                      pinController: controller.confirmPin,
                      obscureText: false,
                      onCompleted: (pin) {
                        controller.confirmOTPCode(pin);
                      },
                    ),
                    SizedBox(height: Design.spacing.lg),
                    AppButton(
                      isExpanded: true,
                      text: AppLocales.auth.confirmEmail.confirmCodeButton.tr,
                      onPressed: () {
                        if (controller.confirmPin.text.length != 6) {
                          controller.confirmPin.triggerError();
                          AppSnackbar.error(
                            AppLocales.auth.confirmEmail.enter6DigitCode.tr,
                          );
                          return;
                        }
                        controller.confirmOTPCode(
                          controller.confirmPin.text,
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: Design.spacing.lg),

              Center(
                child: Obx(
                  () => AppButton(
                    type: EButtonType.text,
                    onPressed: controller.resendSecondsLeft.value > 0
                        ? null
                        : () => controller.sendConfirmationOTPCode(),
                    text: controller.resendSecondsLeft.value > 0
                        ? AppLocales.auth.confirmEmail.resendCodeIn.trParams({
                            'seconds': '${controller.resendSecondsLeft.value}',
                          })
                        : AppLocales.auth.confirmEmail.resendCode.tr,
                  ),
                ),
              ),

              SizedBox(height: Design.spacing.xs),

              AppButton(
                type: EButtonType.text,
                onPressed: () {
                  // Clear everything and go back to auth page
                  controller.email.value = '';
                  controller.confirmPin.clear();
                  Get.offAllNamed(AppRoutes.auth);
                },
                text: AppLocales.auth.shared.useDifferentEmail.tr,
              ),

              SizedBox(height: Design.spacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
