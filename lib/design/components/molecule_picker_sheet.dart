// lib/design/components/molecule_picker_sheet.dart
//
// The post-recording molecule chooser: after a recording becomes an atom,
// the user picks which molecule it belongs to. Dismissing leaves the atom
// uncategorized — both paths are valid.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_locales.dart';
import 'package:rexone_mobile/services/services.dart';

/// Asks which molecule a freshly created atom should be filed under.
/// Returns the picked molecule id, or null when dismissed or when the user
/// has no molecules yet.
Future<String?> showMoleculePickerSheet({
  String? title,
  String? subtitle,
}) async {
  if (Get.find<CategoryService>().categories.isEmpty) return null;

  return Get.bottomSheet<String>(
    _MoleculePickerSheet(title: title, subtitle: subtitle),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

class _MoleculePickerSheet extends StatelessWidget {
  const _MoleculePickerSheet({this.title, this.subtitle});

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categories = Get.find<CategoryService>().categories.toList();

    return AppNeumoSurface(
      radius: Design.spacing.radiusLarge,
      padding: EdgeInsets.all(Design.spacing.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title ?? AppLocales.category.selectTitle.tr,
              style: context.typo.headline3,
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              subtitle ?? AppLocales.molecule.assignSub.tr,
              style: context.typo.bodySmall.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: Design.spacing.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: Design.spacing.sm),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return AppGlassCard(
                    onTap: () => Get.back(result: category.id),
                    padding: EdgeInsets.all(Design.spacing.md),
                    radius: Design.spacing.radiusLarge,
                    child: Row(
                      children: [
                        Icon(
                          Design.icons.molecule,
                          size: Design.spacing.iconSmall,
                          color: colors.primary,
                        ),
                        SizedBox(width: Design.spacing.sm),
                        Expanded(
                          child: Text(
                            category.name,
                            style: context.typo.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
