import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ferret_entry.dart';
import '../export/curl_exporter.dart';
import 'ferret_body_viewer.dart';

/// Full raw request/response detail.
class FerretDetailView extends StatelessWidget {
  const FerretDetailView({
    super.key,
    required this.entry,
    required this.slowThreshold,
    this.onReplay,
    this.onCompare,
  });

  final FerretEntry entry;
  final Duration slowThreshold;
  final VoidCallback? onReplay;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = entry.duration;
    final slow = entry.isSlow(slowThreshold);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${entry.method} ${entry.statusCode ?? '…'}'),
          actions: [
            if (onCompare != null)
              IconButton(
                tooltip: 'Compare',
                onPressed: onCompare,
                icon: const Icon(Icons.compare_arrows_rounded),
              ),
            if (onReplay != null)
              IconButton(
                tooltip: 'Replay',
                onPressed: onReplay,
                icon: const Icon(Icons.replay_rounded),
              ),
            IconButton(
              tooltip: 'Copy as cURL',
              onPressed: () async {
                final curl = const CurlExporter().export(entry);
                await Clipboard.setData(ClipboardData(text: curl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('cURL copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              entry: entry,
              duration: duration,
              slow: slow,
              scheme: scheme,
            ),
            _HeadersBodyTab(
              headers: entry.requestHeaders,
              body: entry.requestBody,
            ),
            _HeadersBodyTab(
              headers: entry.responseHeaders ?? const {},
              body: entry.responseBody,
              error: entry.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.entry,
    required this.duration,
    required this.slow,
    required this.scheme,
  });

  final FerretEntry entry;
  final Duration? duration;
  final bool slow;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SelectableText(
          entry.url.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(label: entry.method, color: scheme.primary),
            _Chip(
              label: entry.client.name,
              color: scheme.secondary,
            ),
            if (entry.statusCode != null)
              _Chip(
                label: '${entry.statusCode}',
                color: entry.isFailed ? scheme.error : scheme.tertiary,
              ),
            if (duration != null)
              _Chip(
                label: '${duration!.inMilliseconds} ms',
                color: slow ? scheme.error : scheme.outline,
              ),
            if (entry.sizeBytes != null)
              _Chip(
                label: _formatBytes(entry.sizeBytes!),
                color: scheme.outline,
              ),
          ],
        ),
        if (entry.error != null) ...[
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            entry.error!,
            style: TextStyle(color: scheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Started',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(entry.startTime.toIso8601String()),
        SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _HeadersBodyTab extends StatelessWidget {
  const _HeadersBodyTab({
    required this.headers,
    required this.body,
    this.error,
  });

  final Map<String, String> headers;
  final Object? body;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sectionStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
      children: [
        Text('Headers', style: sectionStyle),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: headers.isEmpty
                ? const Text('(none)')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e in headers.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: FerretHeaderLine(
                            name: e.key,
                            value: e.value,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          SelectableText(
            error!,
            style: TextStyle(color: scheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Text('Body', style: sectionStyle),
        const SizedBox(height: 8),
        FerretBodyViewer(body: body),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
