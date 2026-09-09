import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../auth/auth.dart';
import '../controllers/home.controller.dart';
import '../data/models/models.dart';

class HomePage extends GetView<AuthController> {
  const HomePage({super.key});

  static const _filters = <String>['All', 'AtomOS', 'New', 'Personal'];

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

    if (homeController.hasAtomsError.value) {
      return _buildErrorState(context);
    }

    final atoms = homeController.atoms;
    if (atoms.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: Design.spacing.lg),
      itemCount: atoms.length + (kDebugMode ? 1 : 0),
      separatorBuilder: (_, index) => SizedBox(height: Design.spacing.md),
      itemBuilder: (context, index) {
        if (index == atoms.length) {
          return _buildDebugTools(context);
        }
        return _buildAtomCard(context, atoms[index]);
      },
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
            color: colors.surface,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: colors.border),
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
            'Hello, $displayName!',
            style: context.typo.headline2.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: Design.spacing.xs),
          Text(
            'Your week, in atoms',
            style: context.typo.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchBar(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Design.spacing.md,
        vertical: Design.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Design.icons.search, color: colors.textMuted),
          SizedBox(width: Design.spacing.sm),
          Expanded(
            child: Text(
              'Search atoms or meetings',
              style: context.typo.bodyMedium.copyWith(color: colors.textMuted),
            ),
          ),
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: colors.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Design.icons.filter,
              size: Design.spacing.iconSmall,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Obx(
      () => Wrap(
        spacing: Design.spacing.sm,
        runSpacing: Design.spacing.sm,
        children: _filters
            .map(
              (label) => _FilterChip(
                label: label,
                selected: label == homeController.selectedFilter.value,
                onTap: () => homeController.selectFilter(label),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Text('Recent', style: context.typo.labelLarge),
        const Spacer(),
        GestureDetector(
          onTap: AppRoutes.toCalendar,
          child: Container(
            height: 30,
            width: 30,
            margin: EdgeInsets.only(right: Design.spacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
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
            color: colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            Design.icons.search,
            size: Design.spacing.iconSmall,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAtomCard(BuildContext context, AtomModel atom) {
    final colors = context.colors;
    final duration = _formatDuration(atom.durationSecs);
    final participants = atom.participantsCount != null &&
            atom.participantsCount! > 0
        ? '${atom.participantsCount} speakers'
        : null;

    return AppCard(
      onTap: () => AppRoutes.toAtomDetail(atomId: atom.id),
      borderRadius: Design.spacing.radiusLarge,
      padding: EdgeInsets.all(Design.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Design.spacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 6,
                      width: 6,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: Design.spacing.xs),
                    Text(
                      atom.source.toUpperCase(),
                      style: context.typo.caption.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Design.icons.more,
                size: Design.spacing.iconSmall,
                color: colors.textMuted,
              ),
            ],
          ),
          SizedBox(height: Design.spacing.md),
          Text(
            atom.title,
            style: context.typo.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (duration.isNotEmpty || participants != null) ...[
            SizedBox(height: Design.spacing.sm),
            Text(
              [duration, participants]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(' · '),
              style: context.typo.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int? secs) {
    if (secs == null || secs <= 0) return '';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingState(BuildContext context) {
    final colors = context.colors;

    return ListView.separated(
      padding: EdgeInsets.only(bottom: Design.spacing.lg),
      itemCount: 3 + (kDebugMode ? 1 : 0),
      separatorBuilder: (_, index) => SizedBox(height: Design.spacing.md),
      itemBuilder: (context, index) {
        if (kDebugMode && index == 3) {
          return _buildDebugTools(context);
        }

        return Container(
          height: 132,
          padding: EdgeInsets.all(Design.spacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
            border: Border.all(color: colors.border),
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
    return _StatusCard(
      icon: Design.icons.emptyBox,
      title: 'No Atoms found',
      subtitle: 'Try another filter or create a new atom.',
      primaryLabel: 'New Atom',
      onPrimaryTap: () => _showCreateSheet(context),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return _StatusCard(
      icon: Design.icons.warning,
      title: 'Could not load your workspace',
      subtitle: 'Check your connection and try again.',
      primaryLabel: 'Retry',
      onPrimaryTap: () => homeController.loadAtoms(),
    );
  }

  Widget _buildBottomDock(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(Design.spacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        border: Border.all(color: colors.border),
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
              label: const Text('Ask Atom'),
            ),
          ),
          SizedBox(width: Design.spacing.sm),
          Expanded(
            child: SizedBox(
              height: Design.spacing.buttonHeight,
              child: ElevatedButton(
                onPressed: () => _showCreateSheet(context),
                child: const Text('New Atom'),
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
              color: colors.card,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Design.spacing.radiusXLarge),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(Design.spacing.lg),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(
                        Design.spacing.radiusXLarge,
                      ),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _SheetTabButton(
                                  label: 'Record',
                                  selected: isRecordTab,
                                  onTap: () => setSheetState(() {
                                    selectedTab = 'record';
                                  }),
                                ),
                              ),
                              SizedBox(width: Design.spacing.xs),
                              Expanded(
                                child: _SheetTabButton(
                                  label: 'Import',
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
                            'Add AtomicOS to live meeting',
                            style: context.typo.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: Design.spacing.sm),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Design.spacing.md,
                              vertical: Design.spacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(
                                Design.spacing.radiusLarge,
                              ),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'https://meet.google.com/abc-defg-hij',
                                    style: context.typo.bodySmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Design.icons.link,
                                  size: Design.spacing.iconSmall,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: Design.spacing.sm),
                          SizedBox(
                            height: Design.spacing.buttonHeight,
                            child: ElevatedButton(
                              onPressed: () {
                                Get.back();
                                AppRoutes.toAi(mode: 'meeting');
                              },
                              child: const Text('Add Now'),
                            ),
                          ),
                          SizedBox(height: Design.spacing.lg),
                          _NewAtomAction(
                            icon: Design.icons.mic,
                            title: 'Record Now',
                            iconColor: colors.primary,
                            onTap: () {
                              Get.back();
                              AppRoutes.toAi(mode: 'meeting');
                            },
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: () {
                              Get.back();
                              AppRoutes.toAtomCreate(mode: 'import');
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Design.spacing.md,
                                vertical: Design.spacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(
                                  Design.spacing.radiusLarge,
                                ),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Paste youtube URL',
                                      style: context.typo.bodyMedium.copyWith(
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Design.icons.link,
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: Design.spacing.lg),
                          _NewAtomAction(
                            icon: Design.icons.folder,
                            title: 'Upload a file',
                            subtitle: 'Audio, Video or documents',
                            onTap: () {
                              Get.back();
                              AppRoutes.toAtomCreate(mode: 'import');
                            },
                          ),
                          SizedBox(height: Design.spacing.md),
                          _NewAtomAction(
                            icon: Design.icons.shareIos,
                            title: 'Share from another app',
                            subtitle: 'Via iOS share sheet',
                            onTap: () {
                              Get.back();
                              AppRoutes.toAtomCreate(mode: 'share');
                            },
                          ),
                          SizedBox(height: Design.spacing.lg),
                          Row(
                            children: [
                              Expanded(child: Divider(color: colors.border)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Design.spacing.md,
                                ),
                                child: Text(
                                  'Or',
                                  style: context.typo.bodySmall.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: colors.border)),
                            ],
                          ),
                          SizedBox(height: Design.spacing.lg),
                          _NewAtomAction(
                            icon: Design.icons.mic,
                            title: 'Record Now',
                            iconColor: colors.primary,
                            onTap: () {
                              Get.back();
                              AppRoutes.toAi(mode: 'meeting');
                            },
                          ),
                          SizedBox(height: Design.spacing.md),
                          _NewAtomAction(
                            icon: Design.icons.atomAdd,
                            title: 'Add AtomicOS to live meeting',
                            onTap: () {
                              setSheetState(() {
                                selectedTab = 'record';
                              });
                            },
                          ),
                          SizedBox(height: Design.spacing.md),
                          _NewAtomAction(
                            icon: Design.icons.clipboard,
                            title: 'Note',
                            subtitle: 'Manually Type or Paste Text',
                            onTap: () {
                              Get.back();
                              AppRoutes.toAtomCreate(mode: 'note');
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

  Widget _buildDebugTools(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dev tools',
          style: context.typo.caption.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: Design.spacing.sm),
        Wrap(
          spacing: Design.spacing.sm,
          runSpacing: Design.spacing.sm,
          children: [
            _StateChip(
              label: 'Content',
              selected: homeController.previewState.value == 'content',
              onTap: () => homeController.setPreviewState('content'),
            ),
            _StateChip(
              label: 'Loading',
              selected: homeController.previewState.value == 'loading',
              onTap: () => homeController.setPreviewState('loading'),
            ),
            _StateChip(
              label: 'Empty',
              selected: homeController.previewState.value == 'empty',
              onTap: () => homeController.setPreviewState('empty'),
            ),
            _StateChip(
              label: 'Error',
              selected: homeController.previewState.value == 'error',
              onTap: () => homeController.setPreviewState('error'),
            ),
          ],
        ),
        SizedBox(height: Design.spacing.sm),
        AppButton(
          type: EButtonType.secondary,
          text: 'Open Calendar',
          onPressed: AppRoutes.toCalendar,
        ),
        SizedBox(height: Design.spacing.sm),
        AppButton(
          type: EButtonType.secondary,
          text: 'Open Live Activity',
          onPressed: AppRoutes.toLiveActivity,
        ),
        SizedBox(height: Design.spacing.sm),
        AppButton(
          type: EButtonType.secondary,
          text: 'Send manual test log',
          onPressed: _sendTestLog,
        ),
      ],
    );
  }

  Future<void> _sendTestLog() async {
    try {
      final log = Get.find<LogService>();
      await log.logError(
        'Manual test log from HomePage',
        context: {
          'source': 'dev_button',
          'route': Get.currentRoute,
          'user': controller.currentUser.value?.email ?? 'unknown',
        },
        severity: 'info',
      );
      AppSnackbar.success('Test log sent to backend');
    } catch (e) {
      AppSnackbar.error('Failed: $e');
    }
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
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
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

class _StateChip extends StatelessWidget {
  const _StateChip({
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
          color: selected ? colors.primary.withValues(alpha: 0.16) : colors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: context.typo.bodySmall.copyWith(
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: FontWeight.w600,
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
                color: colors.surface,
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
