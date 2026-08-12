import 'package:flutter/material.dart';

import '../config/ferret_config.dart';
import '../core/ferret_stats.dart';
import '../core/ferret_store.dart';
import 'dashboard/ferret_dashboard_app_bar.dart';
import 'dashboard/ferret_dashboard_body.dart';
import 'dashboard/ferret_dashboard_search.dart';
import 'dashboard/ferret_detail_route.dart';
import 'ferret_export_sheet.dart';
import 'ferret_filter.dart';
import 'ferret_theme.dart';

/// Full inspector: call list, search, filters, cURL / HAR export.
class FerretDashboard extends StatefulWidget {
  const FerretDashboard({
    super.key,
    required this.store,
    required this.config,
    this.onClear,
  });

  final FerretStore store;
  final FerretConfig config;
  final VoidCallback? onClear;

  @override
  State<FerretDashboard> createState() => _FerretDashboardState();
}

class _FerretDashboardState extends State<FerretDashboard> {
  FerretFilter _filter = FerretFilter.empty;
  final _search = FerretDashboardSearch();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stats = FerretStats.fromStore(widget.store.entries, widget.config);
    final entries = _filter.apply(
      widget.store.entries,
      slowThreshold: widget.config.slowThreshold,
    );

    return FerretTheme.wrap(
      context,
      (context) => Scaffold(
        appBar: FerretDashboardAppBar(
          subtitle: stats.statusLine,
          searchOpen: _search.open,
          hasActiveFilters: _filter.isActive,
          onToggleSearch: () => _search.toggle(_refresh),
          onExport: () => FerretExportSheet.showSession(
            context,
            entries: widget.store.entries,
          ),
          onClear: widget.onClear,
        ),
        body: FerretDashboardBody(
          searchOpen: _search.open,
          searchController: _search.controller,
          searchFocus: _search.focus,
          filter: _filter,
          onQueryChanged: (value) {
            setState(() => _filter = _filter.copyWith(query: value));
          },
          onFilterChanged: (filter) => setState(() => _filter = filter),
          store: widget.store,
          entries: entries,
          config: widget.config,
          onOpen: (entry) => FerretDetailRoute.open(
            context,
            store: widget.store,
            entry: entry,
            slowThreshold: widget.config.slowThreshold,
          ),
        ),
      ),
    );
  }
}
