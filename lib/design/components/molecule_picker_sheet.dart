// lib/design/components/molecule_picker_sheet.dart
//
// Molecule choosers.
//
// `showMoleculePickerSheet` is the post-recording chooser: after a recording
// becomes an atom, the user picks which molecule it belongs to. Dismissing
// leaves the atom uncategorized — both paths are valid.
//
// `showMoleculePickerForAsk` is the ask chooser: asking the AI starts by
// naming its neuron, so selection is REQUIRED (dismissing cancels the ask)
// and a "create new neuron" row quick-adds a missing one on the spot.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_locales.dart';
import 'package:rexone_mobile/modules/home/data/models/category.model.dart';
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

/// The ask chooser: asking the AI must name its neuron first. Selection is
/// required — dismissing cancels the ask — and the trailing row quick-adds a
/// missing neuron (name dialog → create → resolves with the fresh neuron) so
/// creation and selection are one gesture.
Future<CategoryModel?> showMoleculePickerForAsk({
  String? title,
  String? subtitle,
}) {
  final service = Get.find<CategoryService>();
  // Best-effort freshness: the sheet lists what is loaded and updates live
  // when this lands.
  unawaited(service.refresh());

  return Get.bottomSheet<CategoryModel>(
    _AskMoleculePickerSheet(title: title, subtitle: subtitle),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

class _AskMoleculePickerSheet extends StatefulWidget {
  const _AskMoleculePickerSheet({this.title, this.subtitle});

  final String? title;
  final String? subtitle;

  @override
  State<_AskMoleculePickerSheet> createState() =>
      _AskMoleculePickerSheetState();
}

class _AskMoleculePickerSheetState extends State<_AskMoleculePickerSheet> {
  bool _creating = false;

  /// Name dialog → create → resolve the sheet with the fresh neuron, so the
  /// ask routes straight into it.
  Future<void> _createNeuron() async {
    if (_creating) return;

    final textController = TextEditingController();
    final name = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        ),
        title: Text(
          AppLocales.category.createNew.tr,
          style: context.typo.headline4.copyWith(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: AppLocales.category.nameHint.tr,
          ),
          onSubmitted: (value) {
            Get.closeAllSnackbars();
            Get.back(result: value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.closeAllSnackbars();
              Get.back();
            },
            child: Text(AppLocales.common.cancel.tr),
          ),
          TextButton(
            onPressed: () {
              Get.closeAllSnackbars();
              Get.back(result: textController.text.trim());
            },
            child: Text(AppLocales.category.add.tr),
          ),
        ],
      ),
    );

    final clean = name?.trim() ?? '';
    if (clean.isEmpty) return;

    setState(() => _creating = true);
    try {
      final service = Get.find<CategoryService>();
      final result = await service.create(clean);
      if (!result.success) {
        AppSnackbar.error(result.error ?? result.message);
        return;
      }
      await service.refresh();
      final created = result.data;
      if (created == null || created.id.isEmpty) return;
      // GetX's back() closes an open snackbar INSTEAD of popping a route,
      // so the sheet must pop first and the confirmation toast follows it.
      if (mounted) {
        Get.back(result: created);
      }
      AppSnackbar.success(AppLocales.category.created.tr);
    } catch (error, stackTrace) {
      AppSnackbar.error(AppLocales.common.error.tr, e: error, stk: stackTrace);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final service = Get.find<CategoryService>();

    return AppNeumoSurface(
      radius: Design.spacing.radiusLarge,
      padding: EdgeInsets.all(Design.spacing.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title ?? AppLocales.category.selectTitle.tr,
              style: context.typo.headline3,
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              widget.subtitle ?? AppLocales.molecule.assignSub.tr,
              style: context.typo.bodySmall.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: Design.spacing.md),
            Obx(() {
              final categories = service.categories.toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (categories.isEmpty) ...[
                    Text(
                      AppLocales.category.empty.tr,
                      style: context.typo.bodySmall.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    SizedBox(height: Design.spacing.sm),
                  ],
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: categories.length + 1,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: Design.spacing.sm),
                        itemBuilder: (context, index) {
                          if (index == categories.length) {
                            return _buildCreateRow(context);
                          }
                          return _buildMoleculeRow(context, categories[index]);
                        },
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMoleculeRow(BuildContext context, CategoryModel category) {
    final colors = context.colors;

    return AppGlassCard(
      onTap: _creating ? () {} : () => Get.back(result: category),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typo.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRow(BuildContext context) {
    final colors = context.colors;

    return AppGlassCard(
      onTap: _creating ? () {} : _createNeuron,
      padding: EdgeInsets.all(Design.spacing.md),
      radius: Design.spacing.radiusLarge,
      child: Row(
        children: [
          Icon(
            Design.icons.add,
            size: Design.spacing.iconSmall,
            color: colors.primary,
          ),
          SizedBox(width: Design.spacing.sm),
          Expanded(
            child: Text(
              AppLocales.category.createNew.tr,
              style: context.typo.labelMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_creating)
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
