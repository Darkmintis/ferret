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

/// Header line with a bold name and value aligned in a right-hand column.
///
/// Multi-line values stay indented under the value (to the right of `name:`).
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
    final keyStyle = base?.copyWith(fontWeight: FontWeight.w700);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$name: ', style: keyStyle),
        Expanded(
          child: SelectableText(
            value,
            style: base,
          ),
        ),
      ],
    );
  }
}
