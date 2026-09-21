// lib/modules/setting/pages/admin_categories.page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/modules/home/data/models/category.model.dart';
import 'package:rexone_mobile/services/services.dart';

/// Admin-only screen: create and remove the categories users attach to atoms.
/// Reachable from Settings when GET /v1/users/current/iam says is_admin.
class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  final CategoryService _categories = Get.find<CategoryService>();
  final TextEditingController _nameController = TextEditingController();
  final RxBool _isSaving = false.obs;

  @override
  void initState() {
    super.initState();
    _categories.refresh();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSaving.value) return;

    _isSaving.value = true;
    final result = await _categories.create(name);
    _isSaving.value = false;

    if (result.success) {
      _nameController.clear();
      AppSnackbar.success(AppLocales.category.created.tr);
      await _categories.refresh();
    } else {
      AppSnackbar.error(result.error ?? result.message);
    }
  }

  Future<void> _delete(CategoryModel category) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppLocales.category.deleteTitle.tr,
      message: AppLocales.category.deleteMessage.tr,
      confirmLabel: AppLocales.common.delete.tr,
      confirmColor: context.colors.error,
    );
    if (!confirmed) return;

    final result = await _categories.delete(category.id);
    if (result.success) {
      AppSnackbar.success(AppLocales.category.deleted.tr);
      await _categories.refresh();
    } else {
      AppSnackbar.error(result.error ?? result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppPage(
      title: AppLocales.category.title.tr,
      showBackButton: true,
      child: Padding(
        padding: EdgeInsets.all(Design.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppGlassCard(
              radius: Design.spacing.radiusLarge,
              padding: EdgeInsets.all(Design.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInputField(
                    label: AppLocales.category.nameHint.tr,
                    hint: '',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {},
                    onSubmitted: _add,
                  ),
                  SizedBox(height: Design.spacing.md),
                  Obx(
                    () => AppButton(
                      text: AppLocales.category.add.tr,
                      icon: Design.icons.add,
                      isExpanded: true,
                      onPressed: _isSaving.value ? null : _add,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Design.spacing.xl),
            Expanded(
              child: Obx(() {
                final categories = _categories.categories;
                if (categories.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocales.category.empty.tr,
                      style: context.typo.bodyMedium.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, index) =>
                      SizedBox(height: Design.spacing.md),
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    return AppCard(
                      borderRadius: Design.spacing.radiusMedium,
                      padding: EdgeInsets.symmetric(
                        horizontal: Design.spacing.lg,
                        vertical: Design.spacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Design.icons.category,
                            size: Design.spacing.iconSmall,
                            color: colors.primary,
                          ),
                          SizedBox(width: Design.spacing.md),
                          Expanded(
                            child: Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.typo.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _delete(category),
                            child: Padding(
                              padding: EdgeInsets.all(Design.spacing.xs),
                              child: Icon(
                                Design.icons.delete,
                                size: Design.spacing.iconSmall,
                                color: colors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
