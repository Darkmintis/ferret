import 'dart:convert';

import 'package:flutter/material.dart';

/// Formats bodies and header lines for Ferret detail tabs.
abstract final class FerretBodyViewer {
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

/// Header line with a bold name and wrapping value (safe on narrow widths).
class FerretHeaderLine extends StatelessWidget {
  const FerretHeaderLine({
    super.key,
    required this.name,
    required this.value,
    this.emphasize = false,
  });

  final String name;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodyMedium;
    final keyStyle = base?.copyWith(
      fontWeight: FontWeight.w700,
      color: emphasize ? scheme.primary : null,
    );

    return SelectableText.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '$name: ', style: keyStyle),
          TextSpan(
            text: value,
            style: emphasize ? base?.copyWith(fontWeight: FontWeight.w600) : null,
          ),
        ],
      ),
    );
  }
}
