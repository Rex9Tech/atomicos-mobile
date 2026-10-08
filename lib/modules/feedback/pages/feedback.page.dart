// lib/modules/feedback/pages/feedback.page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';

import '../controllers/feedback.controller.dart';

/// Full-screen feedback form.
///
/// Was a bottom sheet — its keyboard handling was unreliable (closing the
/// sheet could leave the IME floating over the next screen, and scrolling
/// moved the close button off-screen). As a regular screen, back
/// navigation + [KeyboardDismissObserver] give the keyboard its normal
/// lifecycle.
class FeedbackPage extends GetView<FeedbackController> {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showTimeZone: false,
      title: AppLocales.feedback.title.tr,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.lg,
          vertical: Design.spacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Slider Bar (1 to 10)
            Obx(
              () => AppRatingSlider(
                value: controller.rating.value.toDouble(),
                onChanged: (val) => controller.setRating(val.round()),
                label: AppLocales.feedback.rateExperience.tr,
              ),
            ),
            SizedBox(height: Design.spacing.lg),

            // Feedback input field
            AppInputField(
              label: AppLocales.feedback.tellUsMore.tr,
              hint: AppLocales.feedback.placeholder.tr,
              controller: controller.textController,
              maxLines: 6,
              minLines: 5,
              onChanged: (_) {},
            ),
            SizedBox(height: Design.spacing.xl),

            // Submit Button
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: controller.isSubmitting.value
                    ? const Center(child: AppLoading())
                    : AppButton(
                        text: AppLocales.feedback.submit.tr,
                        onPressed: () => controller.submitFeedback(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
