// lib/modules/notification/pages/notification.page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/routes/routes.dart';
import '../controllers/notification.controller.dart';
import '../data/models/notification.model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final NotificationController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchNotifications(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  void _handleNotificationTap(NotificationModel item) {
    _controller.markAsRead(item);

    if (item.link != null && item.link!.isNotEmpty) {
      AppRoutes.handleNotificationLink(item.link);
    }
  }

  /// Flat list of [_DayHeader] separators + notifications for the ListView.
  List<Object> _buildRows() {
    final rows = <Object>[];
    DateTime? currentDay;

    for (final item in _controller.notifications) {
      final created = item.createdAt.toLocal();
      final day = DateTime(created.year, created.month, created.day);

      if (currentDay == null || day != currentDay) {
        rows.add(_DayHeader(day));
        currentDay = day;
      }
      rows.add(item);
    }
    return rows;
  }

  Widget _buildDayHeader(BuildContext context, DateTime day) {
    return Padding(
      padding: EdgeInsets.only(
        top: Design.spacing.xs,
        bottom: Design.spacing.xs,
      ),
      child: Text(
        _dayLabel(context, day),
        style: context.typo.labelMedium.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return AppLocales.notification.today.tr;
    if (diff == 1) return AppLocales.notification.yesterday.tr;
    return MaterialLocalizations.of(context).formatMediumDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return AppPage(
      title: AppLocales.notification.title.tr,
      showBackButton: true,
      actions: [
        Obx(() {
          final hasUnread = _controller.unreadCount.value > 0;
          return AppButton(
            type: EButtonType.icon,
            icon: Design.icons.checkAll,
            tooltip: AppLocales.notification.markAllAsRead.tr,
            color: hasUnread
                ? colors.primary
                : colors.textSecondary.withValues(alpha: 0.5),
            onPressed: hasUnread
                ? () {
                    _controller.markAllAsRead();
                    AppSnackbar.success(
                      AppLocales.notification.markAllAsRead.tr,
                    );
                  }
                : null,
          );
        }),
      ],
      child: Column(
        children: [
          // ── Filter Segment Bar ──────────────────────────────
          // The strip is the track the tabs sit in, so it reads as a well;
          // only the active tab lifts out of it.
          AppNeumoSurface(
            depth: ENeumoDepth.inset,
            radius: 0,
            padding: EdgeInsets.symmetric(
              horizontal: Design.spacing.lg,
              vertical: Design.spacing.md,
            ),
            child: Obx(
              () => Row(
                children: [
                  _buildFilterTab(
                    label: AppLocales.notification.all.tr,
                    filter: NotificationConstants.filterAll,
                    isActive:
                        _controller.currentFilter.value ==
                        NotificationConstants.filterAll,
                  ),
                  SizedBox(width: Design.spacing.sm),
                  _buildFilterTab(
                    label: AppLocales.notification.unread.tr,
                    filter: NotificationConstants.filterUnread,
                    badgeCount: _controller.unreadCount.value,
                    isActive:
                        _controller.currentFilter.value ==
                        NotificationConstants.filterUnread,
                  ),
                  SizedBox(width: Design.spacing.sm),
                  _buildFilterTab(
                    label: AppLocales.notification.read.tr,
                    filter: NotificationConstants.filterRead,
                    isActive:
                        _controller.currentFilter.value ==
                        NotificationConstants.filterRead,
                  ),
                ],
              ),
            ),
          ),

          // ── Notifications List ─────────────────────────────
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value &&
                  _controller.notifications.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: colors.primary),
                );
              }

              if (_controller.notifications.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      _controller.fetchNotifications(refresh: true),
                  color: colors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Design.icons.bell,
                              size: 64,
                              color: colors.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            SizedBox(height: Design.spacing.md),
                            Text(
                              AppLocales.notification.empty.tr,
                              style: typo.bodyLarge.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final rows = _buildRows();

              return RefreshIndicator(
                onRefresh: () => _controller.fetchNotifications(refresh: true),
                color: colors.primary,
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: Design.spacing.lg,
                    vertical: Design.spacing.md,
                  ),
                  itemCount:
                      rows.length + (_controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (context, index) {
                    final hasNext = index + 1 < rows.length;
                    if (hasNext && rows[index + 1] is _DayHeader) {
                      return SizedBox(height: Design.spacing.lg);
                    }
                    return SizedBox(height: Design.spacing.sm);
                  },
                  itemBuilder: (context, index) {
                    if (index == rows.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Design.spacing.lg,
                        ),
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

                    final row = rows[index];
                    if (row is _DayHeader) {
                      return _buildDayHeader(context, row.day);
                    }
                    return _buildNotificationCard(
                      context,
                      row as NotificationModel,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required String filter,
    int? badgeCount,
    required bool isActive,
  }) {
    final colors = context.colors;
    final typo = context.typo;

    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.changeFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: Design.spacing.sm),
          decoration: BoxDecoration(
            // Blended rather than translucent so the thumb stays opaque over
            // the recessed track and its lift shadow reads cleanly.
            color: isActive
                ? Color.alphaBlend(
                    colors.primary.withValues(alpha: 0.16),
                    colors.neumo,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
            boxShadow: isActive ? colors.neumoShadowSoft : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mirror spacer: the count badge must not push the label off
              // center — reserve equal width on the left when a badge shows.
              if (badgeCount != null && badgeCount > 0)
                const SizedBox(width: 22),
              // One small label size for ALL tabs (tester: 'consistent small
              // font texts — like All and Read same as Unread'). The label
              // ellipsizes as a last resort instead of scaling per-tab, which
              // used to leave each filter at a different visual size.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: typo.labelMedium.copyWith(
                    color: isActive ? colors.primary : colors.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount > 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(
                      Design.spacing.radiusMedium,
                    ),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    maxLines: 1,
                    style: typo.caption.copyWith(
                      color: colors.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel item) {
    final colors = context.colors;
    final typo = context.typo;

    return Dismissible(
      key: Key('notif_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _controller.deleteNotification(item);
        AppSnackbar.info(AppLocales.notification.deleted.tr);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: Design.spacing.xl),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
        ),
        child: Icon(Design.icons.delete, color: colors.onError),
      ),
      child: AppCard(
        padding: EdgeInsets.all(Design.spacing.md),
        // Read items sit on the default neumo fill (with its convex wash);
        // unread keeps a soft green tint as the distinction.
        backgroundColor: item.read
            ? null
            : colors.primary.withValues(alpha: 0.05),
        onTap: () => _handleNotificationTap(item),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread Dot or Icon
            Container(
              margin: EdgeInsets.only(
                top: Design.spacing.xs,
                right: Design.spacing.md,
              ),
              child: item.read
                  ? Icon(
                      Design.icons.bell,
                      size: 20,
                      color: colors.textSecondary.withValues(alpha: 0.6),
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

            // Content
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
                          style: item.read
                              ? typo.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w500,
                                )
                              : typo.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
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
                    style: typo.bodyMedium.copyWith(
                      color: item.read
                          ? colors.textSecondary
                          : colors.textPrimary,
                    ),
                  ),
                  if (item.link != null && item.link!.isNotEmpty) ...[
                    SizedBox(height: Design.spacing.sm),
                    Row(
                      children: [
                        Icon(
                          Design.icons.openLink,
                          size: 14,
                          color: colors.primary,
                        ),
                        SizedBox(width: Design.spacing.xs),
                        // Long deep links must ellipsize, not overflow.
                        Expanded(
                          child: Text(
                            item.link!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typo.caption.copyWith(
                              color: colors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Delete Action
            IconButton(
              icon: Icon(
                Design.icons.close,
                size: 16,
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: AppLocales.common.delete.tr,
              onPressed: () {
                _controller.deleteNotification(item);
                AppSnackbar.info(AppLocales.notification.deleted.tr);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Date separator row in the notifications list ("Today" / "Yesterday" / date).
class _DayHeader {
  const _DayHeader(this.day);

  final DateTime day;
}
