// lib/design/components/app_search_filter_bar.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rexone_mobile/design/design.dart';

/// Item model representing a quick filter chip in [AppSearchBar].
class AppSearchChipItem {
  final String id;
  final String label;
  final IconData? icon;

  const AppSearchChipItem({required this.id, required this.label, this.icon});
}

/// Reusable search input and filter bar component.
///
/// Features:
/// - Search input with search icon, clear button, and optional trailing loading indicator
/// - Built-in debouncing timer (default 350ms) to avoid spamming the backend
/// - Filter trigger button with optional active filter count badge
/// - Optional horizontal quick-filter chip row
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.hint = 'Search...',
    this.initialQuery = '',
    required this.onSearchChanged,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.isSearching = false,
    this.filterChips = const [],
    this.selectedFilterId,
    this.onFilterSelected,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.searchController,
  });

  /// Placeholder hint text for the search input.
  final String hint;

  /// Initial query string.
  final String initialQuery;

  /// Callback invoked when debounced search query changes.
  final Function(String query) onSearchChanged;

  /// Duration to wait after keystrokes before calling [onSearchChanged].
  final Duration debounceDuration;

  /// Whether a search request is actively in-flight (shows trailing spinner).
  final bool isSearching;

  /// Optional list of filter chips to display underneath the search field.
  final List<AppSearchChipItem> filterChips;

  /// The currently selected filter chip id, if any.
  final String? selectedFilterId;

  /// Callback invoked when a filter chip is tapped.
  final Function(String id)? onFilterSelected;

  /// Optional callback to open a filter bottom sheet or dialog.
  final VoidCallback? onFilterTap;

  /// Number of active filters to indicate on the filter button badge.
  final int activeFilterCount;

  /// Optional external [TextEditingController].
  final TextEditingController? searchController;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.searchController ??
        TextEditingController(text: widget.initialQuery);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        _controller.text != widget.initialQuery) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.searchController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearchChanged(_controller.text.trim());
    });
    setState(() {});
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasFilterButton = widget.onFilterTap != null;
    final hasChips = widget.filterChips.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row: Search Input + Optional Filter Action Button
        Row(
          children: [
            Expanded(
              child: AppInputField(
                controller: _controller,
                hint: widget.hint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: colors.textMuted,
                ),
                suffixIcon: widget.isSearching
                    ? Padding(
                        padding: EdgeInsets.all(Design.spacing.sm),
                        child: AppLoading(
                          size: LoadingSize.small,
                          color: colors.primary,
                        ),
                      )
                    : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colors.textMuted,
                        ),
                        onPressed: _clearSearch,
                        splashRadius: 16,
                      )
                    : null,
              ),
            ),
            if (hasFilterButton) ...[
              SizedBox(width: Design.spacing.sm),
              _buildFilterButton(context),
            ],
          ],
        ),

        // Optional Quick Filter Chips Row
        if (hasChips) ...[
          SizedBox(height: Design.spacing.sm),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.filterChips.length,
              separatorBuilder: (_, _) => SizedBox(width: Design.spacing.xs),
              itemBuilder: (context, index) {
                final chip = widget.filterChips[index];
                final isSelected = widget.selectedFilterId == chip.id;

                return AppBadge(
                  text: chip.label,
                  icon: chip.icon,
                  type: isSelected
                      ? EBadgeVariant.primary
                      : EBadgeVariant.secondary,
                  onTap: () {
                    widget.onFilterSelected?.call(chip.id);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    final colors = context.colors;
    final hasActive = widget.activeFilterCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: hasActive
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surface,
            borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
            border: Border.all(
              color: hasActive ? colors.primary : colors.border,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Design.spacing.radiusMedium),
              onTap: widget.onFilterTap,
              child: Center(
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: hasActive ? colors.primary : colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        if (hasActive)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '${widget.activeFilterCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
