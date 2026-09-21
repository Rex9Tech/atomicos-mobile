// lib/modules/home/pages/widgets/notification_bell.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/routes/routes.dart';

import '../../../notification/controllers/notification.controller.dart';
import '../../../notification/data/models/notification.model.dart';

/// Bell button that lives beside the home-header avatar. Shows the unread
/// count badge and opens the notifications sheet on tap.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<NotificationController>();

    return GestureDetector(
      onTap: () => showNotificationsSheet(),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final unread = controller.unreadCount.value;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: colors.neumo,
                gradient: colors.neumoGradient,
                shape: BoxShape.circle,
                boxShadow: colors.neumoShadowSoft,
              ),
              child: Icon(
                unread > 0 ? Design.icons.bellActive : Design.icons.bell,
                size: Design.spacing.iconSmall,
                color: unread > 0 ? colors.primary : colors.textSecondary,
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 17),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.background, width: 1.5),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    textAlign: TextAlign.center,
                    style: context.typo.caption.copyWith(
                      color: colors.onPrimary,
                      fontSize: 9,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// Recent notifications in a bottom sheet over the current screen; the full
/// page (filters, pagination, delete) stays one tap away via "View all".
Future<void> showNotificationsSheet() async {
  final controller = Get.find<NotificationController>();

  // Refresh in the background — the sheet renders instantly and updates live.
  controller.fetchNotifications(refresh: true);

  await Get.bottomSheet<void>(
    _NotificationsSheet(controller: controller),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.controller});

  final NotificationController controller;

  static const _maxVisible = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.all(Design.spacing.sm),
      padding: EdgeInsets.fromLTRB(
        Design.spacing.lg,
        Design.spacing.lg,
        Design.spacing.lg,
        Design.spacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.neumo,
        gradient: colors.neumoGradient,
        borderRadius: BorderRadius.circular(Design.spacing.radiusXLarge),
        boxShadow: colors.neumoShadow,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.68,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              SizedBox(height: Design.spacing.md),
              Flexible(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Icon(
          Design.icons.bellActive,
          size: Design.spacing.iconSmall,
          color: colors.primary,
        ),
        SizedBox(width: Design.spacing.sm),
        Expanded(
          child: Text(
            AppLocales.notification.title.tr,
            style: context.typo.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Obx(() {
          final hasUnread = controller.unreadCount.value > 0;
          return GestureDetector(
            onTap: hasUnread
                ? () {
                    controller.markAllAsRead();
                    AppSnackbar.success(
                      AppLocales.notification.markAllAsRead.tr,
                    );
                  }
                : null,
            child: Container(
              padding: EdgeInsets.all(Design.spacing.xs + 2),
              decoration: BoxDecoration(
                color: colors.neumo,
                gradient: colors.neumoGradient,
                shape: BoxShape.circle,
                boxShadow: colors.neumoShadowSoft,
              ),
              child: Icon(
                Design.icons.checkAll,
                size: 18,
                color: hasUnread
                    ? colors.primary
                    : colors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final items = controller.notifications;

      if (controller.isLoading.value && items.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: Design.spacing.xl),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ),
        );
      }

      if (items.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: Design.spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Design.icons.bell,
                size: 40,
                color: colors.textSecondary.withValues(alpha: 0.35),
              ),
              SizedBox(height: Design.spacing.md),
              Text(
                AppLocales.notification.empty.tr,
                style: context.typo.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      final visible = items.take(_maxVisible).toList();

      return ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: visible.length + 1,
        separatorBuilder: (_, index) => SizedBox(
          height: index == visible.length - 1 ? 0 : Design.spacing.sm,
        ),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return _buildViewAll(context);
          }
          return _NotificationRow(item: visible[index], controller: controller);
        },
      );
    });
  }

  Widget _buildViewAll(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(top: Design.spacing.md),
      child: GestureDetector(
        onTap: () {
          Get.closeAllSnackbars();
          Get.back();
          AppRoutes.toNotifications();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: Design.spacing.sm + 2),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            AppLocales.notification.viewAll.tr,
            textAlign: TextAlign.center,
            style: context.typo.labelMedium.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.controller});

  final NotificationModel item;
  final NotificationController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return GestureDetector(
      onTap: () {
        controller.markAsRead(item);
        Get.closeAllSnackbars();
        Get.back();

        if (item.link != null && item.link!.isNotEmpty) {
          AppRoutes.handleNotificationLink(item.link);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(Design.spacing.md),
        decoration: BoxDecoration(
          color: colors.neumo,
          gradient: colors.neumoGradient,
          borderRadius: BorderRadius.circular(Design.spacing.radiusLarge),
          boxShadow: colors.neumoShadowSoft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 4, right: Design.spacing.sm),
              child: item.read
                  ? Icon(
                      Design.icons.bell,
                      size: 16,
                      color: colors.textSecondary.withValues(alpha: 0.5),
                    )
                  : Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: Design.colors.shadows.neon,
                      ),
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typo.bodyMedium.copyWith(
                            fontWeight: item.read
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: item.read
                                ? colors.textPrimary
                                : colors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: Design.spacing.sm),
                      Text(
                        formatTimeAgo(item.createdAt),
                        style: typo.caption.copyWith(
                          color: colors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Design.spacing.xs),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodySmall.copyWith(
                      color: item.read
                          ? colors.textSecondary
                          : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
