import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/ferret_config.dart';
import '../core/ferret_entry.dart';
import '../core/ferret_stats.dart';
import '../core/ferret_store.dart';
import '../export/curl_exporter.dart';
import '../export/share_exporter.dart';
import 'ferret_detail_view.dart';
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
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchOpen = false;

  bool get _hasActiveFilters =>
      _filter.query.trim().isNotEmpty ||
      _filter.failedOnly ||
      _filter.slowOnly ||
      _filter.methods.isNotEmpty ||
      (_filter.domain != null && _filter.domain!.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      _searchFocus.unfocus();
    }
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  List<FerretEntry> get _visible => _filter.apply(
        widget.store.entries,
        slowThreshold: widget.config.slowThreshold,
      );

  @override
  Widget build(BuildContext context) {
    final entries = _visible;
    final stats = FerretStats.fromStore(
      widget.store.entries,
      widget.config,
    );

    return FerretTheme.wrap(
      context,
      (context) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ferret'),
              Text(
                stats.statusLine,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _searchOpen ? 'Hide search' : 'Search & filter',
              isSelected: _searchOpen || _hasActiveFilters,
              onPressed: _toggleSearch,
              icon: Icon(
                _searchOpen ? Icons.search_off_rounded : Icons.search_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Share HAR',
              onPressed: () => _openExportSheet(context),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            if (widget.onClear != null)
              IconButton(
                tooltip: 'Clear all',
                onPressed: widget.onClear,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: Column(
          children: [
            if (_searchOpen)
              _SearchPanel(
                searchController: _search,
                searchFocus: _searchFocus,
                filter: _filter,
                onQueryChanged: (value) {
                  setState(() {
                    _filter = _filter.copyWith(query: value);
                  });
                },
                onFilterChanged: (filter) => setState(() => _filter = filter),
              ),
            Expanded(
              child: _CallsList(
                entries: entries,
                slowThreshold: widget.config.slowThreshold,
                onOpen: _openDetail,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(FerretEntry entry) {
    final entryId = entry.id;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 120),
        reverseTransitionDuration: const Duration(milliseconds: 100),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) {
              final live = widget.store.getById(entryId) ?? entry;
              return FerretDetailView(
                entry: live,
                slowThreshold: widget.config.slowThreshold,
              );
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _openExportSheet(BuildContext context) async {
    final entries = widget.store.entries;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export')),
      );
      return;
    }

    const exporter = ShareExporter();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Export session'),
                subtitle: Text('HAR · cURL per call from the list'),
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Share HAR'),
                subtitle: const Text('Chrome DevTools compatible'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.shareSessionHar(entries);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy HAR'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.copySessionHar(entries);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('HAR copied')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Share HAR (redacted)'),
                subtitle: const Text('Masks tokens / auth on export only'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.shareSessionHar(entries, redact: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.searchController,
    required this.searchFocus,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final FerretFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<FerretFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            focusNode: searchFocus,
            decoration: InputDecoration(
              hintText: 'Search method, host, URL, status…',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: onQueryChanged,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Failed'),
                selected: filter.failedOnly,
                onSelected: (v) {
                  onFilterChanged(filter.copyWith(failedOnly: v));
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Slow'),
                selected: filter.slowOnly,
                onSelected: (v) {
                  onFilterChanged(filter.copyWith(slowOnly: v));
                },
              ),
              const SizedBox(width: 8),
              for (final method
                  in const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']) ...[
                FilterChip(
                  label: Text(method),
                  selected: filter.methods.contains(method),
                  onSelected: (v) {
                    final next = {...filter.methods};
                    if (v) {
                      next.add(method);
                    } else {
                      next.remove(method);
                    }
                    onFilterChanged(filter.copyWith(methods: next));
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CallsList extends StatelessWidget {
  const _CallsList({
    required this.entries,
    required this.slowThreshold,
    required this.onOpen,
  });

  final List<FerretEntry> entries;
  final Duration slowThreshold;
  final ValueChanged<FerretEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'No HTTP calls yet.\nFire a request to see it here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView.separated(
      padding: EdgeInsets.only(bottom: 24 + bottomInset),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final failed = entry.isFailed;
        final slow = entry.isSlow(slowThreshold);
        final path = entry.url.path.isEmpty ? '/' : entry.url.path;
        final query = entry.url.hasQuery ? '?${entry.url.query}' : '';
        final methodColor = failed
            ? scheme.error
            : slow
                ? scheme.tertiary
                : scheme.primary;

        return InkWell(
          onTap: () => onOpen(entry),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    entry.method,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: methodColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$path$query',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (entry.statusCode != null)
                            _MetaChip(
                              label: '${entry.statusCode}',
                              emphasis: failed,
                              color: failed ? scheme.error : scheme.onSurface,
                            ),
                          if (entry.isPending)
                            _MetaChip(
                              label: 'pending',
                              color: scheme.onSurfaceVariant,
                            ),
                          if (entry.sizeBytes != null)
                            _MetaChip(
                              label: _formatBytes(entry.sizeBytes!),
                              color: scheme.onSurfaceVariant,
                            ),
                          if (entry.duration != null)
                            _MetaChip(
                              label: '${entry.duration!.inMilliseconds} ms',
                              emphasis: slow,
                              color: slow
                                  ? scheme.tertiary
                                  : scheme.onSurfaceVariant,
                            ),
                          if (failed && entry.error != null)
                            _MetaChip(
                              label: 'failed',
                              emphasis: true,
                              color: scheme.error,
                            ),
                          if (slow)
                            _MetaChip(
                              label: 'slow',
                              emphasis: true,
                              color: scheme.tertiary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy as cURL',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: const CurlExporter().export(entry),
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('cURL copied')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    this.emphasis = false,
  });

  final String label;
  final Color color;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
