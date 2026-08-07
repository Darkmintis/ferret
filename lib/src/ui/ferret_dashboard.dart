import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/ferret_config.dart';
import '../core/ferret_entry.dart';
import '../core/ferret_stats.dart';
import '../core/ferret_store.dart';
import '../export/curl_exporter.dart';
import '../export/session_exporter.dart';
import '../export/share_exporter.dart';
import 'ferret_detail_view.dart';
import 'ferret_diff_view.dart';
import 'ferret_filter.dart';
import 'ferret_timeline.dart';

/// Full inspector: list, filters, timeline, export.
class FerretDashboard extends StatefulWidget {
  const FerretDashboard({
    super.key,
    required this.store,
    required this.config,
    required this.onReplay,
    this.onClear,
  });

  final FerretStore store;
  final FerretConfig config;
  final Future<void> Function(FerretEntry entry) onReplay;
  final VoidCallback? onClear;

  @override
  State<FerretDashboard> createState() => _FerretDashboardState();
}

class _FerretDashboardState extends State<FerretDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  FerretFilter _filter = FerretFilter.empty;
  final _search = TextEditingController();
  String? _compareId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _tabs.dispose();
    _search.dispose();
    super.dispose();
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

    return Scaffold(
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
            tooltip: 'Export / share',
            onPressed: () => _openExportSheet(context),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                widget.onClear?.call();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear all'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Calls'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search method, URL, status…',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(query: value);
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Failed'),
                  selected: _filter.failedOnly,
                  onSelected: (v) {
                    setState(() {
                      _filter = _filter.copyWith(failedOnly: v);
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Slow'),
                  selected: _filter.slowOnly,
                  onSelected: (v) {
                    setState(() {
                      _filter = _filter.copyWith(slowOnly: v);
                    });
                  },
                ),
                const SizedBox(width: 8),
                for (final method in const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']) ...[
                  FilterChip(
                    label: Text(method),
                    selected: _filter.methods.contains(method),
                    onSelected: (v) {
                      setState(() {
                        final next = {..._filter.methods};
                        if (v) {
                          next.add(method);
                        } else {
                          next.remove(method);
                        }
                        _filter = _filter.copyWith(methods: next);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CallsList(
                  entries: entries,
                  slowThreshold: widget.config.slowThreshold,
                  compareId: _compareId,
                  onOpen: _openDetail,
                  onToggleCompare: (entry) {
                    setState(() {
                      if (_compareId == entry.id) {
                        _compareId = null;
                      } else if (_compareId == null) {
                        _compareId = entry.id;
                      } else {
                        final left = widget.store.getById(_compareId!);
                        _compareId = null;
                        if (left != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FerretDiffView(
                                left: left,
                                right: entry,
                              ),
                            ),
                          );
                        }
                      }
                    });
                  },
                ),
                FerretTimeline(
                  entries: entries,
                  slowThreshold: widget.config.slowThreshold,
                  onTap: _openDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(FerretEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FerretDetailView(
          entry: entry,
          slowThreshold: widget.config.slowThreshold,
          onReplay: () => widget.onReplay(entry),
          onCompare: () {
            setState(() => _compareId = entry.id);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Select another call to compare'),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openExportSheet(BuildContext context) async {
    const exporter = ShareExporter();
    final entries = widget.store.entries;
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
                title: Text('Export / share'),
                subtitle: Text('HAR · JSON · Text · Markdown'),
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Share HAR'),
                subtitle: const Text('Chrome DevTools compatible'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.shareSession(
                    entries,
                    config: widget.config,
                    format: FerretExportFormat.har,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_object_rounded),
                title: const Text('Share JSON'),
                subtitle: const Text('Compact call list + stats'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.shareSession(
                    entries,
                    config: widget.config,
                    format: FerretExportFormat.json,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notes_rounded),
                title: const Text('Share text summary'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.shareSession(
                    entries,
                    config: widget.config,
                    format: FerretExportFormat.text,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Share Markdown'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.shareSession(
                    entries,
                    config: widget.config,
                    format: FerretExportFormat.markdown,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy HAR'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.copySession(
                    entries,
                    config: widget.config,
                    format: FerretExportFormat.har,
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('HAR copied')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_all_rounded),
                title: const Text('Copy text summary'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.copySession(
                    entries,
                    config: widget.config,
                    format: FerretExportFormat.text,
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Summary copied')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Share HAR (redacted)'),
                subtitle: const Text('Masks tokens / auth on export only'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await exporter.shareSession(
                    entries,
                    config: widget.config,
                    format: FerretExportFormat.har,
                    redact: true,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CallsList extends StatelessWidget {
  const _CallsList({
    required this.entries,
    required this.slowThreshold,
    required this.compareId,
    required this.onOpen,
    required this.onToggleCompare,
  });

  final List<FerretEntry> entries;
  final Duration slowThreshold;
  final String? compareId;
  final ValueChanged<FerretEntry> onOpen;
  final ValueChanged<FerretEntry> onToggleCompare;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No HTTP calls yet.\nFire a request to see it here.'),
        // textAlign via DefaultTextStyle? Center doesn't set textAlign
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final failed = entry.isFailed;
        final slow = entry.isSlow(slowThreshold);
        final selected = compareId == entry.id;

        return ListTile(
          selected: selected,
          leading: CircleAvatar(
            backgroundColor: failed
                ? scheme.errorContainer
                : slow
                    ? scheme.tertiaryContainer
                    : scheme.primaryContainer,
            child: Text(
              entry.method.substring(0, entry.method.length.clamp(0, 4)),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: failed
                    ? scheme.onErrorContainer
                    : slow
                        ? scheme.onTertiaryContainer
                        : scheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            entry.url.path.isEmpty ? '/' : entry.url.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              entry.host,
              if (entry.statusCode != null) '${entry.statusCode}',
              if (entry.duration != null) '${entry.duration!.inMilliseconds}ms',
              if (failed) 'failed',
              if (slow) 'slow',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: 'Copy cURL',
            icon: const Icon(Icons.terminal_rounded, size: 20),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: const CurlExporter().export(entry)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('cURL copied')),
                );
              }
            },
          ),
          onTap: () {
            if (compareId != null) {
              onToggleCompare(entry);
            } else {
              onOpen(entry);
            }
          },
          onLongPress: () => onToggleCompare(entry),
        );
      },
    );
  }
}
