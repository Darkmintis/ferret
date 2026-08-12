import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ferret_entry.dart';
import '../export/curl_exporter.dart';
import 'ferret_body_viewer.dart';
import 'ferret_theme.dart';

/// Full raw request/response detail.
class FerretDetailView extends StatelessWidget {
  const FerretDetailView({
    super.key,
    required this.entry,
    required this.slowThreshold,
  });

  final FerretEntry entry;
  final Duration slowThreshold;

  @override
  Widget build(BuildContext context) {
    return FerretTheme.wrap(context, (context) {
      final scheme = Theme.of(context).colorScheme;
      final duration = entry.duration;
      final slow = entry.isSlow(slowThreshold);

      return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${entry.method} ${entry.statusCode ?? '…'}'),
            actions: [
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
                Tab(text: 'Error'),
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
              _MessageTab(
                kind: _MessageKind.request,
                headers: entry.requestHeaders,
                body: entry.requestBody,
              ),
              _MessageTab(
                kind: _MessageKind.response,
                headers: entry.responseHeaders ?? const {},
                body: entry.responseBody,
              ),
              _ErrorTab(error: entry.error),
            ],
          ),
        ),
      );
    });
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(label: entry.method, color: scheme.primary),
            _Chip(label: entry.client.name, color: scheme.secondary),
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
        const SizedBox(height: 16),
        Text(
          'Started',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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

enum _MessageKind { request, response }

class _MessageTab extends StatelessWidget {
  const _MessageTab({
    required this.kind,
    required this.headers,
    required this.body,
  });

  final _MessageKind kind;
  final Map<String, String> headers;
  final Object? body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bodyText = FerretBodyViewer.formatBody(body);
    final isEmpty = headers.isEmpty && bodyText.isEmpty;

    if (isEmpty) {
      return _EmptyState(
        icon: kind == _MessageKind.request
            ? Icons.upload_outlined
            : Icons.download_outlined,
        title: kind == _MessageKind.request
            ? 'No request data'
            : 'No response data',
        message: kind == _MessageKind.request
            ? 'This call had no request headers or body.'
            : 'No response headers or body were captured for this call.',
      );
    }

    return ColoredBox(
      color: scheme.surface,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
        children: [
          if (headers.isNotEmpty) ...[
            Text(
              'Headers:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in headers.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: FerretHeaderLine(name: e.key, value: e.value),
                    ),
                ],
              ),
            ),
          ],
          if (bodyText.isNotEmpty) ...[
            if (headers.isNotEmpty) const SizedBox(height: 16),
            Text(
              'Body:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SelectableText.rich(
                FerretBodyViewer.highlightJsonKeys(
                  bodyText,
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: scheme.onSurface,
                      ) ??
                      const TextStyle(height: 1.45),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorTab extends StatelessWidget {
  const _ErrorTab({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = error?.trim() ?? '';

    if (text.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No error',
        message: 'This call completed without an error.',
      );
    }

    return ColoredBox(
      color: scheme.surface,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SelectableText(
            text,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
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
