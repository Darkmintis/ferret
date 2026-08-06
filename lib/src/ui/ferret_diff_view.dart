import 'package:flutter/material.dart';

import '../core/ferret_entry.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: Row(
        children: [
          Expanded(child: _pane(context, 'A', left)),
          const VerticalDivider(width: 1),
          Expanded(child: _pane(context, 'B', right)),
        ],
      ),
    );
  }

  Widget _pane(BuildContext context, String label, FerretEntry entry) {
    final style = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(label, style: style.titleMedium),
        const SizedBox(height: 8),
        Text('${entry.method} ${entry.statusCode ?? '…'}'),
        const SizedBox(height: 4),
        SelectableText(entry.url.toString(), style: style.bodySmall),
        const SizedBox(height: 12),
        Text(
          'Duration: ${entry.duration?.inMilliseconds ?? '—'} ms',
          style: style.bodyMedium,
        ),
        Text(
          'Size: ${entry.sizeBytes ?? '—'} B',
          style: style.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text('Response body', style: style.titleSmall),
        const SizedBox(height: 8),
        SelectableText(
          '${entry.responseBody ?? '(empty)'}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }
}
