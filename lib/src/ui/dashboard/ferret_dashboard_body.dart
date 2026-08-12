import 'package:flutter/material.dart';

import '../../config/ferret_config.dart';
import '../../core/ferret_entry.dart';
import '../../core/ferret_store.dart';
import '../ferret_filter.dart';
import 'ferret_calls_list.dart';
import 'ferret_search_panel.dart';

/// Dashboard body: optional search panel and call list.
class FerretDashboardBody extends StatelessWidget {
  const FerretDashboardBody({
    super.key,
    required this.searchOpen,
    required this.searchController,
    required this.searchFocus,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.store,
    required this.entries,
    required this.config,
    required this.onOpen,
  });

  final bool searchOpen;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final FerretFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<FerretFilter> onFilterChanged;
  final FerretStore store;
  final List<FerretEntry> entries;
  final FerretConfig config;
  final ValueChanged<FerretEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (searchOpen)
          FerretSearchPanel(
            searchController: searchController,
            searchFocus: searchFocus,
            filter: filter,
            onQueryChanged: onQueryChanged,
            onFilterChanged: onFilterChanged,
          ),
        Expanded(
          child: FerretCallsList(
            entries: entries,
            storeEmpty: store.isEmpty,
            filteredEmpty: !store.isEmpty && entries.isEmpty,
            slowThreshold: config.slowThreshold,
            onOpen: onOpen,
          ),
        ),
      ],
    );
  }
}
