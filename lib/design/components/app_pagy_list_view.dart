// lib/design/components/app_pagy_list_view.dart
import 'package:flutter/material.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';

/// Reusable lazy-loading list view component conforming to Core's Pagy architecture.
///
/// Features:
/// - Pull-to-refresh with native [RefreshIndicator]
/// - Automatic infinite scroll prefetching when scrolled near the end
/// - Seamless bottom loading spinner ([AppLoading]) when [isLoadingMore] is true
/// - Clean initial loading, empty, and error fallback states
/// - Optional scrollable [header] widget (e.g. search & filter bar)
/// - Flexible [separatorBuilder] or default spacing
class AppPagyListView<T> extends StatefulWidget {
  const AppPagyListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.onRetry,
    this.scrollController,
    this.prefetchDistance = 200.0,
    this.header,
    this.emptyWidget,
    this.emptyMessage,
    this.errorWidget,
    this.loadingWidget,
    this.loadMoreWidget,
    this.separatorBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  /// The collection of items to display.
  final List<T> items;

  /// Builder for individual item rows.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Callback triggered when user performs pull-to-refresh.
  final Future<void> Function() onRefresh;

  /// Callback triggered when scrolling within [prefetchDistance] of the end.
  final Future<void> Function() onLoadMore;

  /// Whether the initial page of data is loading.
  final bool isLoading;

  /// Whether a subsequent page of data is loading at the bottom.
  final bool isLoadingMore;

  /// Whether more pages are available from the backend.
  final bool hasMore;

  /// Error message to display when initial load fails.
  final String? errorMessage;

  /// Callback triggered when the retry button is pressed in the error state.
  final VoidCallback? onRetry;

  /// Optional external [ScrollController]. If null, an internal one is managed.
  final ScrollController? scrollController;

  /// Pixel distance from bottom of list to trigger [onLoadMore]. Defaults to 200.
  final double prefetchDistance;

  /// Optional widget displayed at the top of the list (e.g. search and filter bar).
  final Widget? header;

  /// Custom widget displayed when [items] is empty and not loading.
  final Widget? emptyWidget;

  /// Text displayed in the default empty state.
  final String? emptyMessage;

  /// Custom widget displayed when [errorMessage] is non-null and [items] is empty.
  final Widget? errorWidget;

  /// Custom widget displayed when [isLoading] is true and [items] is empty.
  final Widget? loadingWidget;

  /// Custom widget displayed at the bottom when [isLoadingMore] is true.
  final Widget? loadMoreWidget;

  /// Optional separator between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Padding around the scrollable list.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics. Defaults to [AlwaysScrollableScrollPhysics] for reliable pull-to-refresh.
  final ScrollPhysics? physics;

  /// Whether the list should shrink-wrap its contents.
  final bool shrinkWrap;

  @override
  State<AppPagyListView<T>> createState() => _AppPagyListViewState<T>();
}

class _AppPagyListViewState<T> extends State<AppPagyListView<T>> {
  ScrollController? _internalScrollController;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? (_internalScrollController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _effectiveScrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant AppPagyListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScroll);
      _internalScrollController?.removeListener(_handleScroll);
      _effectiveScrollController.addListener(_handleScroll);
    }
  }

  @override
  void dispose() {
    _effectiveScrollController.removeListener(_handleScroll);
    _internalScrollController?.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_effectiveScrollController.hasClients) return;

    final position = _effectiveScrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (currentScroll >= maxScroll - widget.prefetchDistance) {
      if (widget.hasMore && !widget.isLoadingMore && !widget.isLoading) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ??
        EdgeInsets.symmetric(
          horizontal: Design.spacing.screenPadding,
          vertical: Design.spacing.md,
        );

    // Case 1: Initial Loading State
    if (widget.isLoading && widget.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: context.colors.primary,
        child: SingleChildScrollView(
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.header != null) ...[
                widget.header!,
                SizedBox(height: Design.spacing.lg),
              ],
              widget.loadingWidget ?? _buildDefaultLoading(context),
            ],
          ),
        ),
      );
    }

    // Case 2: Initial Error State
    if (widget.errorMessage != null && widget.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: context.colors.primary,
        child: SingleChildScrollView(
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.header != null) ...[
                widget.header!,
                SizedBox(height: Design.spacing.lg),
              ],
              widget.errorWidget ?? _buildDefaultError(context),
            ],
          ),
        ),
      );
    }

    // Case 3: Empty State
    if (!widget.isLoading && widget.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: context.colors.primary,
        child: SingleChildScrollView(
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.header != null) ...[
                widget.header!,
                SizedBox(height: Design.spacing.lg),
              ],
              widget.emptyWidget ?? _buildDefaultEmpty(context),
            ],
          ),
        ),
      );
    }

    // Case 4: Populated List with Infinite Scroll
    final hasHeader = widget.header != null;
    final headerOffset = hasHeader ? 1 : 0;
    final totalItemCount = widget.items.length + headerOffset + (widget.isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: context.colors.primary,
      child: ListView.separated(
        controller: _effectiveScrollController,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        shrinkWrap: widget.shrinkWrap,
        padding: effectivePadding,
        itemCount: totalItemCount,
        separatorBuilder: (context, index) {
          // No separator above or below header or footer loader
          if (hasHeader && index == 0) {
            return SizedBox(height: Design.spacing.lg);
          }
          if (widget.isLoadingMore && index == totalItemCount - 2) {
            return SizedBox(height: Design.spacing.md);
          }
          if (widget.separatorBuilder != null) {
            final effectiveIndex = hasHeader ? index - 1 : index;
            return widget.separatorBuilder!(context, effectiveIndex);
          }
          return SizedBox(height: Design.spacing.md);
        },
        itemBuilder: (context, index) {
          // Render header
          if (hasHeader && index == 0) {
            return widget.header!;
          }

          // Render bottom loader
          if (widget.isLoadingMore && index == totalItemCount - 1) {
            return widget.loadMoreWidget ?? _buildDefaultLoadMore(context);
          }

          final itemIndex = index - headerOffset;
          final item = widget.items[itemIndex];
          return widget.itemBuilder(context, item, itemIndex);
        },
      ),
    );
  }

  Widget _buildDefaultLoading(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Design.spacing.xxxl * 2),
        child: AppLoading(
          size: LoadingSize.medium,
          color: context.colors.primary,
        ),
      ),
    );
  }

  Widget _buildDefaultError(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.xl,
          vertical: Design.spacing.xxxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: context.colors.error,
            ),
            SizedBox(height: Design.spacing.md),
            Text(
              widget.errorMessage ?? 'Something went wrong while loading.',
              style: context.typo.bodyMedium.copyWith(color: context.colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Design.spacing.lg),
            AppButton(
              text: 'Retry',
              type: EButtonType.primary,
              onPressed: () {
                if (widget.onRetry != null) {
                  widget.onRetry!();
                } else {
                  widget.onRefresh();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Design.spacing.xl,
          vertical: Design.spacing.xxxl * 1.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 52,
              color: context.colors.textMuted.withValues(alpha: 0.6),
            ),
            SizedBox(height: Design.spacing.md),
            Text(
              widget.emptyMessage ?? 'No records found.',
              style: context.typo.bodyMedium.copyWith(
                color: context.colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLoadMore(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Design.spacing.lg),
        child: AppLoading(
          size: LoadingSize.small,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
