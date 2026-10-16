// lib/modules/payment/pages/mmpay_checkout.page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';

import '../payment.dart';

/// MyanMyanPay (MMQR) checkout: the scan-to-pay QR with the MMQR-required UX
/// (MMK amount, expiry countdown, Download QR, "powered by" footer).
class MmpayCheckoutPage extends GetView<MmpayCheckoutController> {
  const MmpayCheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Design.theme.light,
      child: Builder(
        builder: (themeContext) {
          final colors = themeContext.colors;

          return AppPage(
            title: AppLocales.payment.mmpayTitle.tr,
            showBackButton: false,
            backgroundColor: colors.background,
            actions: [
              AppButton(
                type: EButtonType.icon,
                icon: Design.icons.close,
                onPressed: Get.back,
              ),
            ],
            child: Obx(() {
              final status = controller.status.value;
              if (status == 'succeeded') {
                return const Center(child: AppLoading());
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(Design.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount
                    Text(
                      controller.formattedAmount,
                      textAlign: TextAlign.center,
                      style: themeContext.typo.headline1,
                    ),
                    SizedBox(height: Design.spacing.xs),
                    Text(
                      '${AppLocales.payment.mmpayOrderRef.tr}: ${controller.orderId.value}',
                      textAlign: TextAlign.center,
                      style: themeContext.typo.bodySmall.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    SizedBox(height: Design.spacing.lg),

                    // QR card
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(Design.spacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: QrImageView(
                          data: controller.qr.value,
                          version: QrVersions.auto,
                          size: 240,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: Design.spacing.lg),

                    // Status area
                    if (status == 'pending') ...[
                      Text(
                        AppLocales.payment.mmpayScanHint.tr,
                        textAlign: TextAlign.center,
                        style: themeContext.typo.bodyMedium,
                      ),
                      SizedBox(height: Design.spacing.sm),
                      Text(
                        '⏳ ${AppLocales.payment.mmpayExpiresIn.tr} ${controller.countdownLabel}',
                        textAlign: TextAlign.center,
                        style: themeContext.typo.bodyMedium.copyWith(
                          color: colors.warning,
                        ),
                      ),
                      SizedBox(height: Design.spacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: Design.spacing.sm),
                          Text(
                            AppLocales.payment.mmpayWaiting.tr,
                            style: themeContext.typo.bodySmall,
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        status == 'expired'
                            ? AppLocales.payment.mmpayExpired.tr
                            : AppLocales.payment.mmpayFailed.tr,
                        textAlign: TextAlign.center,
                        style: themeContext.typo.bodyMedium.copyWith(
                          color: colors.error,
                        ),
                      ),
                      SizedBox(height: Design.spacing.md),
                      AppButton(
                        text: AppLocales.payment.mmpayGetNewQr.tr,
                        type: EButtonType.primary,
                        isExpanded: true,
                        onPressed: controller.retry,
                      ),
                    ],
                    SizedBox(height: Design.spacing.md),

                    // Save QR
                    if (status == 'pending')
                      AppButton(
                        text: AppLocales.payment.mmpayDownload.tr,
                        type: EButtonType.secondary,
                        isExpanded: true,
                        onPressed: controller.saveQrImage,
                      ),
                    SizedBox(height: Design.spacing.xxl),

                    // Powered-by footer (MMQR compliance)
                    Text.rich(
                      TextSpan(
                        text: '${AppLocales.payment.mmpayPoweredBy.tr}  ',
                        children: const [
                          TextSpan(
                            text: 'myanmyanpay',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: '  ·  MMQR'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: themeContext.typo.bodySmall.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
