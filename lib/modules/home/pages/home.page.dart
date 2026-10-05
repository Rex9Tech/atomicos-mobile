import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../auth/auth.dart';
import '../../search/search.dart';
import '../data/models/models.dart';
import 'widgets/notification_bell.dart';

/// The workspace home: the user's molecules. Each molecule card opens that
/// molecule's atoms; the list of atoms itself lives on the molecule screen.
class HomePage extends GetView<AuthController> {
  const HomePage({super.key});

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
          _buildGreeting(context),
          SizedBox(height: Design.spacing.md),
          _buildSearchBar(context),
          SizedBox(height: Design.spacing.md),
          _buildMoleculesHeader(context),
          SizedBox(height: Design.spacing.md),
          Expanded(child: _buildMoleculesBody(context)),
          SizedBox(height: Design.spacing.md),
          _buildBottomDock(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        AppNeumoSurface(
          soft: true,
          radius: Design.spacing.radiusLarge,
          padding: EdgeInsets.symmetric(
            horizontal: Design.spacing.md,
            vertical: Design.spacing.sm,
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

            return AppNeumoSurface(
              circle: true,
              soft: true,
              width: 32,
              height: 32,
              padding: EdgeInsets.zero,
              color: colors.primary.withValues(alpha: 0.12),
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
          // The search field is a well, pressed into the page — the one place
          // the inset pair reads most clearly against the raised cards.
          child: AppNeumoSurface(
            depth: ENeumoDepth.inset,
            radius: Design.spacing.radiusLarge,
            padding: EdgeInsets.symmetric(
              horizontal: Design.spacing.md,
              vertical: Design.spacing.md,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoleculesHeader(BuildContext context) {
    final colors = context.colors;
    final categoryService = Get.find<CategoryService>();

    return Row(
      children: [
        Expanded(
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocales.home.molecules.tr,
                  style: context.typo.labelLarge,
                ),
                SizedBox(height: 2),
                Text(
                  AppLocales.home.moleculesCount.trParams({
                    'count': '${categoryService.categories.length}',
                  }),
                  style: context.typo.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: Design.spacing.sm),
        // Opposite the title: add a new molecule.
        GestureDetector(
          onTap: () => _showAddMoleculeDialog(context),
          behavior: HitTestBehavior.opaque,
          child: AppNeumoSurface(
            circle: true,
            soft: true,
            width: 38,
            height: 38,
            padding: EdgeInsets.zero,
            child: Icon(
              Design.icons.add,
              size: Design.spacing.iconSmall,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// "+" next to the Molecules title: name a new molecule in a small dialog;
  /// it is created via the user endpoint and the home list refreshes in place.
  Future<void> _showAddMoleculeDialog(BuildContext context) async {
    final categoryService = Get.find<CategoryService>();
    final textController = TextEditingController();
    final name = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        ),
        title: Text(
          AppLocales.category.quickAdd.tr,
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

    final result = await categoryService.create(clean);
    if (result.success) {
      await categoryService.refresh();
      AppSnackbar.success(AppLocales.category.created.tr);
    } else {
      AppSnackbar.error(result.error ?? result.message);
    }
  }

  Widget _buildMoleculesBody(BuildContext context) {
    final categoryService = Get.find<CategoryService>();

    return Obx(() {
      final molecules = categoryService.categories;

      // First load of the list wears the skeleton; later refreshes keep the
      // last state silently (the service never blanks the list on failure).
      if (categoryService.isLoading.value &&
          !categoryService.hasLoaded.value &&
          molecules.isEmpty) {
        return _buildLoadingState(context);
      }

      if (molecules.isEmpty) {
        return _buildNoMoleculesState(context);
      }

      return ListView.separated(
        // Same viewport clipping rule as the other lists: cards scrolled out
        // of the viewport must never paint over the header above.
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.only(
          top: Design.spacing.md,
          bottom: Design.spacing.xxl,
        ),
        itemCount: molecules.length,
        separatorBuilder: (_, index) => SizedBox(height: Design.spacing.sm),
        itemBuilder: (context, index) =>
            _MoleculeCard(molecule: molecules[index]),
      );
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    final colors = context.colors;

    return ListView.separated(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.only(
        top: Design.spacing.md,
        bottom: Design.spacing.xxl,
      ),
      itemCount: 3,
      separatorBuilder: (_, index) => SizedBox(height: Design.spacing.lg),
      itemBuilder: (context, index) {
        return AppNeumoSurface(
          height: 132,
          radius: Design.spacing.radiusXLarge,
          padding: EdgeInsets.all(Design.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                width: 88,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(height: Design.spacing.md),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.divider,
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
                  color: colors.divider,
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
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoMoleculesState(BuildContext context) {
    return _StatusCard(
      icon: Design.icons.molecule,
      title: AppLocales.home.noMolecules.tr,
      subtitle: AppLocales.home.noMoleculesSub.tr,
      primaryLabel: AppLocales.category.manage.tr,
      onPrimaryTap: AppRoutes.toAdminCategories,
    );
  }

  Widget _buildBottomDock(BuildContext context) {
    final colors = context.colors;

    return AppNeumoSurface(
      radius: Design.spacing.radiusXLarge,
      padding: EdgeInsets.all(Design.spacing.sm),
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

          return AppNeumoSurface(
            margin: EdgeInsets.all(Design.spacing.sm),
            radius: Design.spacing.radiusXLarge,
            padding: EdgeInsets.all(Design.spacing.md),
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
                  AppNeumoSurface(
                    radius: Design.spacing.radiusXLarge,
                    padding: EdgeInsets.all(Design.spacing.lg),
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
                        // Segmented track is a groove; only the selected
                        // thumb inside it rises.
                        AppNeumoSurface(
                          depth: ENeumoDepth.inset,
                          soft: true,
                          radius: 999,
                          padding: const EdgeInsets.all(4),
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

/// One molecule in the home list — opens the molecule's atoms.
class _MoleculeCard extends StatelessWidget {
  const _MoleculeCard({required this.molecule});

  final CategoryModel molecule;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () => AppRoutes.toMolecule(
        moleculeId: molecule.id,
        moleculeName: molecule.name,
      ),
      borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
      child: AppNeumoSurface(
        radius: Design.spacing.radiusXLarge,
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.lg,
          vertical: Design.spacing.md,
        ),
        child: Row(
          children: [
            AppNeumoSurface(
              circle: true,
              soft: true,
              width: 40,
              height: 40,
              padding: EdgeInsets.zero,
              color: colors.primary.withValues(alpha: 0.12),
              child: Icon(
                Design.icons.molecule,
                size: Design.spacing.iconSmall,
                color: colors.primary,
              ),
            ),
            SizedBox(width: Design.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    molecule.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    AppLocales.molecule.atomsCount.trParams({
                      'count': '${molecule.atomsCount}',
                    }),
                    style: context.typo.caption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Design.icons.rightArrow,
              size: Design.spacing.iconSmall,
              color: colors.textMuted,
            ),
          ],
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
      child: AppNeumoSurface(
        radius: 999,
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.md,
          vertical: Design.spacing.md,
        ),
        child: Row(
          children: [
            AppNeumoSurface(
              circle: true,
              soft: true,
              width: 34,
              height: 34,
              padding: EdgeInsets.zero,
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
      // The selected thumb lifts out of the groove it sits in.
      child: selected
          ? AppNeumoSurface(
              soft: true,
              radius: 999,
              padding: EdgeInsets.symmetric(vertical: Design.spacing.sm),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: context.typo.labelMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(vertical: Design.spacing.sm),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: context.typo.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}
