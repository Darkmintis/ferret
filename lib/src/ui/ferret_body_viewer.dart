import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Read-only JSON / text body viewer. Sizes to its content.
///
/// JSON object keys are rendered in bold for easier scanning.
class FerretBodyViewer extends StatelessWidget {
  const FerretBodyViewer({
    super.key,
    required this.body,
  });

  final Object? body;

  @override
  Widget build(BuildContext context) {
    final text = formatBody(body);
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: scheme.onSurface,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Copy body',
                visualDensity: VisualDensity.compact,
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
            SelectableText.rich(
              text.isEmpty
                  ? TextSpan(text: '(empty)', style: baseStyle)
                  : highlightJsonKeys(
                      text,
                      baseStyle ?? const TextStyle(height: 1.45),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a captured body for display / copy.
  static String formatBody(Object? body) {
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

  /// Bolds JSON keys like `"userId":` while leaving values normal.
  static TextSpan highlightJsonKeys(String text, TextStyle baseStyle) {
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
    final spans = <TextSpan>[];
    final pattern = RegExp(r'"([^"\\]|\\.)*"\s*:');
    var start = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(text: match.group(0), style: boldStyle));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}

/// Header line with a bold name and normal value.
class FerretHeaderLine extends StatelessWidget {
  const FerretHeaderLine({
    super.key,
    required this.name,
    required this.value,
  });

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return SelectableText.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: name,
            style: base?.copyWith(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: ': '),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
