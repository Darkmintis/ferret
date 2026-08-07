import 'package:flutter/material.dart';

import '../core/ferret_entry.dart';
import 'ferret_body_viewer.dart';
import 'ferret_theme.dart';

/// Side-by-side comparison of two captured calls.
class FerretDiffView extends StatelessWidget {
  const FerretDiffView({
    super.key,
    required this.left,
    required this.right,
  });

  final FerretEntry left;
  final FerretEntry right;

  @override
  Widget build(BuildContext context) {
    return FerretTheme.wrap(
      context,
      (context) => Scaffold(
        appBar: AppBar(title: const Text('Compare')),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _ComparePane(label: 'A', entry: left)),
            VerticalDivider(
              width: 1,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(child: _ComparePane(label: 'B', entry: right)),
          ],
        ),
      ),
    );
  }
}

class _ComparePane extends StatelessWidget {
  const _ComparePane({required this.label, required this.entry});

  final String label;
  final FerretEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final requestBody = FerretBodyViewer.formatBody(entry.requestBody);
    final responseBody = FerretBodyViewer.formatBody(entry.responseBody);
    final error = entry.error?.trim() ?? '';

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          entry.url.toString(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
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
            if (entry.duration != null)
              _Chip(
                label: '${entry.duration!.inMilliseconds} ms',
                color: scheme.outline,
              ),
            if (entry.sizeBytes != null)
              _Chip(
                label: _formatBytes(entry.sizeBytes!),
                color: scheme.outline,
              ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Request'),
        const SizedBox(height: 10),
        _LabeledBlock(
          title: 'Headers:',
          child: entry.requestHeaders.isEmpty
              ? const _Muted('No request headers')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in entry.requestHeaders.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: FerretHeaderLine(name: e.key, value: e.value),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _LabeledBlock(
          title: 'Body:',
          child: requestBody.isEmpty
              ? const _Muted('No request body')
              : SelectableText.rich(
                  FerretBodyViewer.highlightJsonKeys(
                    requestBody,
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          color: scheme.onSurface,
                        ) ??
                        const TextStyle(height: 1.45),
                  ),
                ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Response'),
        const SizedBox(height: 10),
        _LabeledBlock(
          title: 'Headers:',
          child: (entry.responseHeaders == null ||
                  entry.responseHeaders!.isEmpty)
              ? const _Muted('No response headers')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in entry.responseHeaders!.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: FerretHeaderLine(name: e.key, value: e.value),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _LabeledBlock(
          title: 'Body:',
          child: responseBody.isEmpty
              ? const _Muted('No response body')
              : SelectableText.rich(
                  FerretBodyViewer.highlightJsonKeys(
                    responseBody,
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          color: scheme.onSurface,
                        ) ??
                        const TextStyle(height: 1.45),
                  ),
                ),
        ),
        if (error.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Error'),
          const SizedBox(height: 10),
          SelectableText(
            error,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _LabeledBlock extends StatelessWidget {
  const _LabeledBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: child,
        ),
      ],
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
