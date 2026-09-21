// lib/modules/search/pages/search.page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../home/pages/widgets/atom_card.dart';
import '../controllers/search.controller.dart';

/// Shared between Home's search bar and this screen's field so the bar morphs
/// into the field while the route animates.
const String kSearchBarHeroTag = 'home-search-bar';

/// Dedicated search screen: focused field, category chips, results and the
/// "No result found" state.
class SearchPage extends GetView<AtomSearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppPage(
      backgroundColor: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(context),
          SizedBox(height: Design.spacing.md),
          _buildFilterRow(context),
          SizedBox(height: Design.spacing.md),
          Expanded(child: _buildBody(context)),
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
            height: 44,
            width: 44,
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
        SizedBox(width: Design.spacing.sm),
        Expanded(child: _buildSearchField(context)),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colors = context.colors;

    return Hero(
      tag: kSearchBarHeroTag,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Design.spacing.md,
            vertical: Design.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.neumo,
            gradient: colors.neumoGradient,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            boxShadow: colors.neumoShadowSoft,
          ),
          child: Row(
            children: [
              Icon(Design.icons.search, color: colors.textMuted),
              SizedBox(width: Design.spacing.sm),
              Expanded(
                child: TextField(
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  controller: controller.searchController,
                  onChanged: controller.onQueryChanged,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: AppLocales.search.placeholder.tr,
                    hintStyle: context.typo.bodyMedium.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  style: context.typo.bodyMedium,
                ),
              ),
              Obx(
                () => controller.query.value.isEmpty
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: controller.clear,
                        child: Container(
                          height: 26,
                          width: 26,
                          decoration: BoxDecoration(
                            color: colors.card,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Design.icons.close,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    final categoryService = Get.find<CategoryService>();

    return Obx(
      () => Wrap(
        spacing: Design.spacing.sm,
        runSpacing: Design.spacing.sm,
        children: [
          // 'All' is fixed; the rest are the current user's own categories.
          _SearchChip(
            label: AppLocales.home.filterAll.tr,
            selected: controller.selectedFilter.value == 'all',
            onTap: () => controller.selectFilter('all'),
          ),
          for (final category in categoryService.categories)
            _SearchChip(
              label: category.name,
              selected: controller.selectedFilter.value == category.id,
              onTap: () => controller.selectFilter(category.id),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.results.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.isEmptyResult) {
        return _buildEmptyState(context);
      }
      return ListView.separated(
        padding: EdgeInsets.only(bottom: Design.spacing.xl),
        itemCount: controller.results.length,
        separatorBuilder: (_, _) => SizedBox(height: Design.spacing.md),
        itemBuilder: (_, index) => AtomCard(atom: controller.results[index]),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              Icon(
                Design.icons.emptyBox,
                size: 72,
                color: colors.textMuted.withValues(alpha: 0.4),
              ),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Design.icons.search,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: Design.spacing.lg),
          Text(
            AppLocales.search.emptyTitle.tr,
            style: context.typo.headline4.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Design.spacing.xs),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Design.spacing.xl),
            child: Text(
              AppLocales.search.emptyMessage.tr,
              textAlign: TextAlign.center,
              style: context.typo.bodyMedium.copyWith(
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: context.typo.labelMedium.copyWith(
            color: selected ? colors.background : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
