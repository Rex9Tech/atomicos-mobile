import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../auth/auth.dart';
import '../../search/search.dart';
import '../controllers/home.controller.dart';
import 'widgets/atom_card.dart';
import 'widgets/notification_bell.dart';

class HomePage extends GetView<AuthController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final homeController = Get.find<HomeController>();

    return AppPage(
      backgroundColor: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(context),
          SizedBox(height: Design.spacing.md),
          _buildGreeting(context),
          SizedBox(height: Design.spacing.md),
          _buildSearchBar(context),
          SizedBox(height: Design.spacing.md),
          _buildFilterRow(context),
          SizedBox(height: Design.spacing.md),
          _buildSectionHeader(context),
          SizedBox(height: Design.spacing.md),
          Expanded(child: Obx(() => _buildHomeBody(context, homeController))),
          SizedBox(height: Design.spacing.md),
          _buildBottomDock(context),
        ],
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context, HomeController homeController) {
    if (homeController.isLoadingAtoms.value) {
      return _buildLoadingState(context);
    }

    // Only surface the error when there is nothing to show — a failed refresh
    // must never blank out a workspace the user can still read.
    if (homeController.hasAtomsError.value && homeController.atoms.isEmpty) {
      return _buildErrorState(context);
    }

    final atoms = homeController.atoms;
    if (atoms.isEmpty) {
      return _buildEmptyState(context);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Infinite scroll: pull the next page as the user nears the end.
        if (notification.metrics.extentAfter < 320) {
          homeController.loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: Design.spacing.lg),
        itemCount: atoms.length + (homeController.hasMoreAtoms.value ? 1 : 0),
        separatorBuilder: (_, index) => SizedBox(height: Design.spacing.md),
        itemBuilder: (context, index) {
          if (index == atoms.length) {
            return _buildLoadMoreFooter(context, homeController);
          }
          return AtomCard(atom: atoms[index]);
        },
      ),
    );
  }

  /// Footer slot of the atoms list while the next page is being fetched.
  Widget _buildLoadMoreFooter(
    BuildContext context,
    HomeController homeController,
  ) {
    if (!homeController.isLoadingMore.value) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Design.spacing.md),
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Design.icons.home,
                size: Design.spacing.iconSmall,
                color: colors.textSecondary,
              ),
              SizedBox(width: Design.spacing.sm),
              Text(
                'AtomicOS',
                style: context.typo.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const NotificationBell(),
        SizedBox(width: Design.spacing.sm),
        GestureDetector(
          onTap: AppRoutes.toSettings,
          child: Obx(() {
            final user = controller.currentUser.value;
            if (user?.photo != null) {
              return CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(user!.photo!),
              );
            }

            return Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Design.icons.person,
                size: Design.spacing.iconSmall,
                color: colors.primary,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final user = controller.currentUser.value;
      final displayName =
          user?.name?.split(' ').first ??
          user?.username ??
          user?.email.split('@').first ??
          'Robert';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocales.home.greeting.trParams({'name': displayName}),
            style: context.typo.headline2.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: Design.spacing.xs),
          Text(
            AppLocales.home.weekInAtoms.tr,
            style: context.typo.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    });
  }

  /// Tapping the bar opens the dedicated search screen; the pill morphs across
  /// with its hero tag while the route fades.
  Widget _buildSearchBar(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: AppRoutes.toSearch,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: kSearchBarHeroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Design.spacing.md,
              vertical: Design.spacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.neumo,
              gradient: colors.neumoGradient,
              borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
              boxShadow: colors.neumoShadow,
            ),
            child: Row(
              children: [
                Icon(Design.icons.search, color: colors.textMuted),
                SizedBox(width: Design.spacing.sm),
                Expanded(
                  child: Text(
                    AppLocales.search.placeholder.tr,
                    style: context.typo.bodyMedium.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: colors.neumo,
                    gradient: colors.neumoGradient,
                    shape: BoxShape.circle,
                    boxShadow: colors.neumoShadowSoft,
                  ),
                  child: Icon(
                    Design.icons.filter,
                    size: Design.spacing.iconSmall,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final categoryService = Get.find<CategoryService>();

    return Obx(
      () => Wrap(
        spacing: Design.spacing.sm,
        runSpacing: Design.spacing.sm,
        children: [
          // 'All' is fixed; the rest are admin-managed categories.
          _FilterChip(
            label: AppLocales.home.filterAll.tr,
            selected: homeController.selectedFilter.value == 'all',
            onTap: () => homeController.selectFilter('all'),
          ),
          for (final category in categoryService.categories)
            _FilterChip(
              label: category.name,
              selected: homeController.selectedFilter.value == category.id,
              onTap: () => homeController.selectFilter(category.id),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final colors = context.colors;
    final homeController = Get.find<HomeController>();

    return Obx(
      () => Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocales.home.recentAtoms.tr,
                style: context.typo.labelLarge,
              ),
              SizedBox(height: 2),
              Text(
                AppLocales.home.itemsCount.trParams({
                  'count': '${homeController.atoms.length}',
                }),
                style: context.typo.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: AppRoutes.toCalendar,
            child: Container(
              height: 30,
              width: 30,
              margin: EdgeInsets.only(right: Design.spacing.sm),
              decoration: BoxDecoration(
                color: colors.neumo,
                gradient: colors.neumoGradient,
                shape: BoxShape.circle,
                boxShadow: colors.neumoShadowSoft,
              ),
              child: Icon(
                Design.icons.calendar,
                size: Design.spacing.iconSmall,
                color: colors.textSecondary,
              ),
            ),
          ),
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: colors.neumo,
              gradient: colors.neumoGradient,
              shape: BoxShape.circle,
              boxShadow: colors.neumoShadowSoft,
            ),
            child: Icon(
              Design.icons.search,
              size: Design.spacing.iconSmall,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colors = context.colors;

    return ListView.separated(
      padding: EdgeInsets.only(bottom: Design.spacing.lg),
      itemCount: 3,
      separatorBuilder: (_, index) => SizedBox(height: Design.spacing.md),
      itemBuilder: (context, index) {
        return Container(
          height: 132,
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.neumo,
            gradient: colors.neumoGradient,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            boxShadow: colors.neumoShadowSoft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                width: 88,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(height: Design.spacing.md),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(
                    Design.spacing.radiusMedium,
                  ),
                ),
              ),
              SizedBox(height: Design.spacing.sm),
              Container(
                height: 16,
                width: 188,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(
                    Design.spacing.radiusMedium,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 12,
                width: 132,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return _StatusCard(
      icon: Design.icons.emptyBox,
      title: AppLocales.home.noAtoms.tr,
      subtitle:
          homeController.searchQuery.value.isNotEmpty ||
              homeController.selectedFilter.value != 'All'
          ? AppLocales.home.noAtomsFilterSub.tr
          : AppLocales.home.noAtomsEmptySub.tr,
      primaryLabel: AppLocales.home.newAtom.tr,
      onPrimaryTap: () => _showCreateSheet(context),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return _StatusCard(
      icon: Design.icons.warning,
      title: AppLocales.home.loadFailed.tr,
      subtitle: AppLocales.home.loadFailedSub.tr,
      primaryLabel: AppLocales.atom.retry.tr,
      onPrimaryTap: () => homeController.loadAtoms(),
    );
  }

  Widget _buildBottomDock(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(Design.spacing.sm),
      decoration: BoxDecoration(
        color: colors.neumo,
        gradient: colors.neumoGradient,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        boxShadow: colors.neumoShadowSoft,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => AppRoutes.toAi(mode: 'ask'),
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                padding: EdgeInsets.symmetric(vertical: Design.spacing.md),
              ),
              icon: Icon(Design.icons.sparkles, size: Design.spacing.iconSmall),
              label: Text(AppLocales.home.askAtom.tr),
            ),
          ),
          SizedBox(width: Design.spacing.sm),
          Expanded(
            child: SizedBox(
              height: Design.spacing.buttonHeight,
              child: ElevatedButton(
                onPressed: () => _showCreateSheet(context),
                child: Text(AppLocales.home.newAtom.tr),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    final colors = context.colors;
    var selectedTab = 'record';

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final isRecordTab = selectedTab == 'record';

          return Container(
            margin: EdgeInsets.all(Design.spacing.sm),
            padding: EdgeInsets.all(Design.spacing.md),
            decoration: BoxDecoration(
              color: colors.neumo,
              gradient: colors.neumoGradient,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Design.spacing.radiusXLarge),
              ),
              boxShadow: colors.neumoShadow,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 44,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: Design.spacing.md),
                  Container(
                    padding: EdgeInsets.all(Design.spacing.lg),
                    decoration: BoxDecoration(
                      color: colors.neumo,
                      gradient: colors.neumoGradient,
                      borderRadius: BorderRadius.circular(
                        Design.spacing.radiusXLarge,
                      ),
                      boxShadow: colors.neumoShadowSoft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppLocales.home.newAtom.tr,
                          style: context.typo.headline4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: Design.spacing.xs),
                        Text(
                          AppLocales.home.newAtomSheetSub.tr,
                          style: context.typo.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: Design.spacing.lg),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.neumo,
                            gradient: colors.neumoGradient,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: colors.neumoShadowSoft,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _SheetTabButton(
                                  label: AppLocales.create.modeRecord.tr,
                                  selected: isRecordTab,
                                  onTap: () => setSheetState(() {
                                    selectedTab = 'record';
                                  }),
                                ),
                              ),
                              SizedBox(width: Design.spacing.xs),
                              Expanded(
                                child: _SheetTabButton(
                                  label: AppLocales.create.import.tr,
                                  selected: !isRecordTab,
                                  onTap: () => setSheetState(() {
                                    selectedTab = 'import';
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Design.spacing.lg),
                        if (isRecordTab) ...[
                          Text(
                            AppLocales.create.captureLive.tr,
                            style: context.typo.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: Design.spacing.xs),
                          Text(
                            AppLocales.create.captureLiveSub.tr,
                            style: context.typo.bodySmall.copyWith(
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: Design.spacing.md),
                          _NewAtomAction(
                            icon: Design.icons.mic,
                            title: AppLocales.create.recordNow.tr,
                            subtitle: AppLocales.create.recordNowSub.tr,
                            iconColor: colors.primary,
                            onTap: () {
                              Get.back();
                              AppRoutes.toLiveActivity();
                            },
                          ),
                        ] else ...[
                          _NewAtomAction(
                            icon: Design.icons.folder,
                            title: AppLocales.create.uploadFile.tr,
                            subtitle: AppLocales.create.uploadFileSub.tr,
                            onTap: () {
                              Get.back();
                              AppRoutes.toAtomCreate(mode: 'upload');
                            },
                          ),
                          SizedBox(height: Design.spacing.md),
                          _NewAtomAction(
                            icon: Design.icons.clipboard,
                            title: AppLocales.create.noteTitle.tr,
                            subtitle: AppLocales.create.noteSub.tr,
                            onTap: () {
                              Get.back();
                              AppRoutes.toAtomCreate(mode: 'note');
                            },
                          ),
                          SizedBox(height: Design.spacing.md),
                          _NewAtomAction(
                            icon: Design.icons.shareIos,
                            title: AppLocales.create.shareTitle.tr,
                            subtitle: AppLocales.create.shareSub.tr,
                            onTap: () {
                              Get.back();
                              AppRoutes.toAtomCreate(mode: 'share');
                            },
                          ),
                        ],
                        SizedBox(height: Design.spacing.xl),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Design.icons.atomAdd,
                                size: Design.spacing.iconSmall,
                                color: colors.textMuted,
                              ),
                              SizedBox(width: Design.spacing.xs),
                              Text(
                                'AtomicOS',
                                style: context.typo.labelLarge.copyWith(
                                  color: colors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
          color: selected ? colors.primary : colors.neumo,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? null : colors.neumoShadowSoft,
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimaryTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    return AppToneCard(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      tone: EAppToneCardTone.primary,
      padding: EdgeInsets.all(Design.spacing.xl),
      footer: SizedBox(
        width: double.infinity,
        height: Design.spacing.buttonHeight,
        child: ElevatedButton(
          onPressed: onPrimaryTap,
          child: Text(primaryLabel),
        ),
      ),
    );
  }
}

class _NewAtomAction extends StatelessWidget {
  const _NewAtomAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: Design.spacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: colors.neumo,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: Design.spacing.iconSmall,
                color: iconColor ?? colors.textSecondary,
              ),
            ),
            SizedBox(width: Design.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.typo.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: context.typo.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTabButton extends StatelessWidget {
  const _SheetTabButton({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: Design.spacing.sm),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.typo.labelMedium.copyWith(
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
