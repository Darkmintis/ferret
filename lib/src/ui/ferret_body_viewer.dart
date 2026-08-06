import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Read-only JSON / text body viewer with light syntax styling.
class FerretBodyViewer extends StatelessWidget {
  const FerretBodyViewer({
    super.key,
    required this.body,
  });

  final Object? body;

  @override
  Widget build(BuildContext context) {
    final text = _format(body);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Copy',
            onPressed: text.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied body')),
                      );
                    }
                  },
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                text.isEmpty ? '(empty)' : text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.45,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _format(Object? body) {
    if (body == null) return '';
    if (body is String) {
      final trimmed = body.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          final decoded = jsonDecode(trimmed);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } on Object {
          return body;
        }
      }
      return body;
    }
    if (body is List<int>) {
      try {
        return utf8.decode(body);
      } on Object {
        return base64Encode(body);
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } on Object {
      return body.toString();
    }
  }
}
