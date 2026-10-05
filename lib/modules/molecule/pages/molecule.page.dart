// lib/modules/molecule/pages/molecule.page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';

import '../controllers/molecule.controller.dart';
import '../../home/pages/widgets/atom_card.dart';

/// One molecule: every atom organised into it, plus an entry that hands the
/// whole molecule (all of its atoms) to the AI.
class MoleculePage extends StatefulWidget {
  const MoleculePage({super.key});

  @override
  State<MoleculePage> createState() => _MoleculePageState();
}

class _MoleculePageState extends State<MoleculePage> {
  late final MoleculeController controller;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final map = args is Map ? args : const <String, dynamic>{};
    controller = MoleculeController(
      moleculeId: map['molecule_id']?.toString() ?? '',
      moleculeName: map['molecule_name']?.toString() ?? '',
    )..onInit();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppPage(
      backgroundColor: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          SizedBox(height: Design.spacing.md),
          Expanded(child: Obx(() => _buildBody(context))),
          SizedBox(height: Design.spacing.md),
          _buildBottomDock(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        GestureDetector(
          onTap: Get.back,
          child: AppNeumoSurface(
            circle: true,
            soft: true,
            width: 36,
            height: 36,
            padding: EdgeInsets.zero,
            child: Icon(
              Design.icons.backArrow,
              size: Design.spacing.iconSmall,
              color: colors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: Design.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.moleculeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typo.headline4.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Obx(
                () => Text(
                  (controller.atoms.length == 1
                          ? AppLocales.molecule.atomsCountOne
                          : AppLocales.molecule.atomsCount)
                      .trParams({
                    'count': '${controller.atoms.length}',
                  }),
                  style: context.typo.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value) {
      return _buildLoading(context);
    }
    if (controller.hasError.value && controller.atoms.isEmpty) {
      return _buildError(context);
    }
    if (controller.atoms.isEmpty) {
      return _buildEmpty(context);
    }

    final atoms = controller.atoms;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 320) {
          controller.loadMore();
        }
        return false;
      },
      child: ListView.separated(
        // Same viewport clipping rule as the workspace lists: cards must not
        // paint over the pinned header.
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.only(
          top: Design.spacing.md,
          bottom: Design.spacing.xxl,
        ),
        itemCount: atoms.length + (controller.hasMore.value ? 1 : 0),
        separatorBuilder: (_, index) => SizedBox(height: Design.spacing.lg),
        itemBuilder: (context, index) {
          if (index == atoms.length) {
            return _buildLoadMoreFooter(context);
          }
          return AtomCard(atom: atoms[index]);
        },
      ),
    );
  }

  Widget _buildLoadMoreFooter(BuildContext context) {
    if (!controller.isLoadingMore.value) {
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

  Widget _buildLoading(BuildContext context) {
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Design.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Design.icons.emptyBox,
              size: 44,
              color: colors.textMuted,
            ),
            SizedBox(height: Design.spacing.md),
            Text(
              AppLocales.molecule.empty.tr,
              textAlign: TextAlign.center,
              style: context.typo.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              AppLocales.molecule.emptySub.tr,
              textAlign: TextAlign.center,
              style: context.typo.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Design.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Design.icons.warning, size: 44, color: colors.textMuted),
            SizedBox(height: Design.spacing.md),
            Text(
              AppLocales.molecule.loadFailed.tr,
              textAlign: TextAlign.center,
              style: context.typo.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              AppLocales.molecule.loadFailedSub.tr,
              textAlign: TextAlign.center,
              style: context.typo.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: Design.spacing.lg),
            SizedBox(
              width: 180,
              height: Design.spacing.buttonHeight,
              child: ElevatedButton(
                onPressed: controller.reload,
                child: Text(AppLocales.atom.retry.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hands the whole molecule — every atom inside it — to the AI.
  Widget _buildBottomDock(BuildContext context) {
    final colors = context.colors;

    return AppNeumoSurface(
      radius: Design.spacing.radiusXLarge,
      padding: EdgeInsets.all(Design.spacing.sm),
      child: SizedBox(
        height: Design.spacing.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: () => AppRoutes.toAi(
            mode: 'ask',
            moleculeId: controller.moleculeId,
            moleculeName: controller.moleculeName,
          ),
          icon: Icon(
            Design.icons.sparkles,
            size: Design.spacing.iconSmall,
            color: colors.onPrimary,
          ),
          label: Text(AppLocales.molecule.ask.tr),
        ),
      ),
    );
  }
}
