// lib/design/components/recording_language_sheet.dart
//
// The recording-language chooser: shown when a live recording starts so the
// user picks what the live transcript should recognize (Burmese or English).
// Native labels stay in their own script; the last pick is persisted.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_locales.dart';
import 'package:rexone_mobile/services/services.dart';

/// Native labels for the live-STT languages the recorder can choose from.
const Map<String, String> recordingLanguageOptions = {
  'my-MM': 'မြန်မာ',
  'en-US': 'English',
};

/// Native label for a live-STT language code (falls back to the code).
String recordingLanguageLabel(String code) =>
    recordingLanguageOptions[code] ?? code;

/// Asks which language an upcoming live recording should transcribe.
/// Preselects the last choice (or the locale default); an explicit pick is
/// persisted and applied to [SpeechService.recordingLanguage]. Dismissing
/// keeps the current selection. Returns the language code that will be used.
Future<String> showRecordingLanguageSheet() async {
  final speech = Get.find<SpeechService>();
  final storage = Get.find<StorageService>();
  final current = speech.recordingLanguage.value.isNotEmpty
      ? speech.recordingLanguage.value
      : (storage.getRecordingLanguage() ?? speech.sttLanguage);

  final picked = await Get.bottomSheet<String>(
    _RecordingLanguageSheet(current: current),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );

  final applied = picked ?? current;
  speech.recordingLanguage.value = applied;
  if (picked != null) {
    storage.setRecordingLanguage(picked);
  }
  return applied;
}

class _RecordingLanguageSheet extends StatelessWidget {
  const _RecordingLanguageSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppNeumoSurface(
      radius: Design.spacing.radiusLarge,
      padding: EdgeInsets.all(Design.spacing.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocales.recording.languageTitle.tr,
              style: context.typo.headline3,
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              AppLocales.recording.languageSub.tr,
              style: context.typo.bodySmall.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: Design.spacing.md),
            for (final entry in recordingLanguageOptions.entries)
              Padding(
                padding: EdgeInsets.only(bottom: Design.spacing.sm),
                child: AppGlassCard(
                  onTap: () => Get.back(result: entry.key),
                  padding: EdgeInsets.all(Design.spacing.md),
                  radius: Design.spacing.radiusLarge,
                  shadow: entry.key == current
                      ? <BoxShadow>[
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.30),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value,
                          style: context.typo.labelMedium.copyWith(
                            color: entry.key == current
                                ? colors.primary
                                : colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (entry.key == current)
                        Icon(
                          Design.icons.check,
                          size: Design.spacing.iconSmall,
                          color: colors.primary,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
