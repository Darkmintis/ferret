import 'package:flutter/material.dart';

import '../ferret_theme.dart';

/// App bar for the Ferret inspector dashboard.
class FerretDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const FerretDashboardAppBar({
    super.key,
    required this.subtitle,
    required this.searchOpen,
    required this.hasActiveFilters,
    required this.onToggleSearch,
    required this.onExport,
    this.onClear,
  });

  final String subtitle;
  final bool searchOpen;
  final bool hasActiveFilters;
  final VoidCallback onToggleSearch;
  final VoidCallback onExport;
  final VoidCallback? onClear;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: FerretTheme.brandTitle(context, subtitle: subtitle),
      actions: [
        IconButton(
          tooltip: searchOpen ? 'Hide search' : 'Search & filter',
          isSelected: searchOpen || hasActiveFilters,
          onPressed: onToggleSearch,
          icon: Icon(
            searchOpen ? Icons.search_off_rounded : Icons.search_rounded,
          ),
        ),
        IconButton(
          tooltip: 'Share HAR',
          onPressed: onExport,
          icon: const Icon(Icons.ios_share_rounded),
        ),
        if (onClear != null)
          IconButton(
            tooltip: 'Clear all',
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
    );
  }
}
