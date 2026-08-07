import 'dart:convert';

import '../core/ferret_entry.dart';

/// Which detail-tab content to render into an SVG.
enum FerretSvgPane {
  overview,
  request,
  response,
  error,
}

/// Builds a shareable SVG that mirrors Ferret detail (or session cards).
class SvgExporter {
  const SvgExporter();

  static const _width = 720.0;
  static const _pad = 24.0;
  static const _contentWidth = _width - _pad * 2;
  static const _monoChars = 86;
  static const _bodyChars = 78;
  static const _maxLines = 4000;

  /// Single-call SVG for a detail pane (full scrollable content).
  String exportEntry(
    FerretEntry entry, {
    FerretSvgPane pane = FerretSvgPane.overview,
    bool redact = false,
  }) {
    return switch (pane) {
      FerretSvgPane.overview => _overview(entry, redact: redact),
      FerretSvgPane.request => _message(
          entry,
          pane: pane,
          headers: entry.requestHeaders,
          body: entry.requestBody,
          redact: redact,
        ),
      FerretSvgPane.response => _message(
          entry,
          pane: pane,
          headers: entry.responseHeaders ?? const {},
          body: entry.responseBody,
          redact: redact,
        ),
      FerretSvgPane.error => _error(entry, redact: redact),
    };
  }

  /// Session SVG — stacked summary cards (capped for readability).
  String export(
    List<FerretEntry> entries, {
    bool redact = false,
    int max = 12,
  }) {
    final visible = entries.take(max).toList(growable: false);
    const cardH = 168.0;
    const gap = 16.0;
    final height = _pad * 2 +
        40 +
        (visible.isEmpty
            ? cardH
            : visible.length * cardH + (visible.length - 1) * gap);
    final buffer = StringBuffer()
      ..write(_docOpen(height))
      ..writeln(_brandHeader())
      ..writeln(
        '<text x="${_width - _pad}" y="36" text-anchor="end" '
        'font-family="ui-sans-serif,system-ui,sans-serif" font-size="12" '
        'fill="#5A6B62">${_esc(DateTime.now().toUtc().toIso8601String())}</text>',
      );

    if (visible.isEmpty) {
      buffer.writeln(_emptyCard(_pad, 56, _contentWidth, cardH, 'No calls to export'));
    } else {
      var y = 56.0;
      for (final entry in visible) {
        buffer.writeln(
          _summaryCard(
            entry,
            x: _pad,
            y: y,
            width: _contentWidth,
            height: cardH,
            redact: redact,
          ),
        );
        y += cardH + gap;
      }
      if (entries.length > max) {
        buffer.writeln(
          '<text x="$_pad" y="${height - 10}" '
          'font-family="ui-sans-serif,system-ui,sans-serif" font-size="11" '
          'fill="#5A6B62">+${entries.length - max} more calls not shown</text>',
        );
      }
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  String _overview(FerretEntry entry, {required bool redact}) {
    final url = redact
        ? entry.url.replace(query: '').toString()
        : entry.url.toString();
    final urlLines = _wrap(url, _bodyChars);
    final chips = <String>[
      entry.method,
      entry.client.name,
      if (entry.statusCode != null) '${entry.statusCode}',
      if (entry.duration != null) '${entry.duration!.inMilliseconds} ms',
      if (entry.sizeBytes != null) _formatBytes(entry.sizeBytes!),
    ];
    final chipLine = chips.join('   ·   ');
    final started = entry.startTime.toIso8601String();

    final blocks = <_SvgBlock>[
      _SvgBlock.gap(8),
      ...urlLines.map((l) => _SvgBlock.text(l, size: 16, weight: 700, color: '#13201A')),
      _SvgBlock.gap(14),
      _SvgBlock.text(chipLine, size: 13, color: '#1B6B4A'),
      _SvgBlock.gap(20),
      _SvgBlock.text('Started', size: 13, weight: 700, color: '#13201A'),
      _SvgBlock.gap(6),
      _SvgBlock.text(started, size: 13, color: '#3A4A42'),
    ];

    return _paneDocument(
      entry: entry,
      pane: FerretSvgPane.overview,
      redact: redact,
      blocks: blocks,
    );
  }

  String _message(
    FerretEntry entry, {
    required FerretSvgPane pane,
    required Map<String, String> headers,
    required Object? body,
    required bool redact,
  }) {
    final bodyText = _formatBody(body);
    final isEmpty = headers.isEmpty && bodyText.isEmpty;
    final blocks = <_SvgBlock>[];

    if (isEmpty) {
      final title = pane == FerretSvgPane.request
          ? 'No request data'
          : 'No response data';
      final message = pane == FerretSvgPane.request
          ? 'This call had no request headers or body.'
          : 'No response headers or body were captured for this call.';
      blocks
        ..add(_SvgBlock.gap(40))
        ..add(_SvgBlock.text(title, size: 16, weight: 700, color: '#13201A', center: true))
        ..add(_SvgBlock.gap(8))
        ..add(_SvgBlock.text(message, size: 13, color: '#5A6B62', center: true));
    } else {
      if (headers.isNotEmpty) {
        blocks
          ..add(_SvgBlock.gap(4))
          ..add(_SvgBlock.text('Headers:', size: 14, weight: 700, color: '#13201A'))
          ..add(_SvgBlock.gap(10));
        for (final e in headers.entries) {
          final value = redact && _sensitiveHeader(e.key)
              ? '••••••••'
              : e.value;
          final lines = _wrapHeader(e.key, value);
          for (var i = 0; i < lines.length; i++) {
            blocks.add(
              _SvgBlock.text(
                lines[i],
                size: 13,
                weight: i == 0 ? 700 : 400,
                color: '#13201A',
                mono: false,
                indent: 12,
              ),
            );
          }
          blocks.add(_SvgBlock.gap(6));
        }
      }

      if (bodyText.isNotEmpty) {
        if (headers.isNotEmpty) blocks.add(_SvgBlock.gap(10));
        blocks
          ..add(_SvgBlock.text('Body:', size: 14, weight: 700, color: '#13201A'))
          ..add(_SvgBlock.gap(10));
        var lines = _wrapPreserveNewlines(bodyText, _monoChars);
        var truncated = false;
        if (lines.length > _maxLines) {
          lines = lines.take(_maxLines).toList(growable: false);
          truncated = true;
        }
        for (final line in lines) {
          blocks.add(
            _SvgBlock.text(
              line.isEmpty ? ' ' : line,
              size: 12,
              color: '#3A4A42',
              mono: true,
              indent: 12,
            ),
          );
        }
        if (truncated) {
          blocks
            ..add(_SvgBlock.gap(8))
            ..add(
              _SvgBlock.text(
                '… truncated after $_maxLines lines',
                size: 11,
                color: '#5A6B62',
                indent: 12,
              ),
            );
        }
      }
    }

    return _paneDocument(
      entry: entry,
      pane: pane,
      redact: redact,
      blocks: blocks,
    );
  }

  String _error(FerretEntry entry, {required bool redact}) {
    final text = entry.error?.trim() ?? '';
    final blocks = <_SvgBlock>[];
    if (text.isEmpty) {
      blocks
        ..add(_SvgBlock.gap(40))
        ..add(
          _SvgBlock.text(
            'No error',
            size: 16,
            weight: 700,
            color: '#13201A',
            center: true,
          ),
        )
        ..add(_SvgBlock.gap(8))
        ..add(
          _SvgBlock.text(
            'This call completed without an error.',
            size: 13,
            color: '#5A6B62',
            center: true,
          ),
        );
    } else {
      blocks.add(_SvgBlock.gap(4));
      for (final line in _wrapPreserveNewlines(text, _bodyChars)) {
        blocks.add(
          _SvgBlock.text(
            line.isEmpty ? ' ' : line,
            size: 13,
            weight: 600,
            color: '#B3261E',
          ),
        );
      }
    }

    return _paneDocument(
      entry: entry,
      pane: FerretSvgPane.error,
      redact: redact,
      blocks: blocks,
    );
  }

  String _paneDocument({
    required FerretEntry entry,
    required FerretSvgPane pane,
    required bool redact,
    required List<_SvgBlock> blocks,
  }) {
    final status = entry.statusCode?.toString() ??
        (entry.error != null ? 'ERR' : '…');
    final failed = entry.isFailed;
    final accent = failed ? '#B3261E' : '#1B6B4A';
    final paneLabel = switch (pane) {
      FerretSvgPane.overview => 'Overview',
      FerretSvgPane.request => 'Request',
      FerretSvgPane.response => 'Response',
      FerretSvgPane.error => 'Error',
    };

    var y = 56.0;
    final content = StringBuffer();
    for (final block in blocks) {
      if (block.isGap) {
        y += block.gap;
        continue;
      }
      final x = block.center
          ? _width / 2
          : _pad + block.indent;
      final anchor = block.center ? 'middle' : 'start';
      final family = block.mono
          ? 'ui-monospace,SFMono-Regular,Menlo,Consolas,monospace'
          : 'ui-sans-serif,system-ui,sans-serif';
      content.writeln(
        '<text x="$x" y="$y" text-anchor="$anchor" '
        'font-family="$family" font-size="${block.size}" '
        'font-weight="${block.weight}" fill="${block.color}">'
        '${_esc(block.text)}</text>',
      );
      y += block.size + 6;
    }
    y += _pad;
    final height = y < 200 ? 200.0 : y;

    final buffer = StringBuffer()
      ..write(_docOpen(height))
      ..writeln(
        '<rect width="100%" height="100%" fill="#FFFFFF"/>',
      )
      ..writeln(
        '<rect x="0" y="0" width="$_width" height="48" fill="#F4F7F5"/>',
      )
      ..writeln(
        '<text x="$_pad" y="30" font-family="ui-sans-serif,system-ui,sans-serif" '
        'font-size="15" font-weight="700" fill="$accent">'
        '${_esc(entry.method)} ${_esc(status)}</text>',
      )
      ..writeln(
        '<text x="${_width / 2}" y="30" text-anchor="middle" '
        'font-family="ui-sans-serif,system-ui,sans-serif" font-size="13" '
        'font-weight="600" fill="#13201A">${_esc(paneLabel)}</text>',
      )
      ..writeln(
        '<text x="${_width - _pad}" y="30" text-anchor="end" '
        'font-family="ui-sans-serif,system-ui,sans-serif" font-size="13" '
        'font-weight="700" fill="#13201A">Ferret</text>',
      )
      ..writeln(
        '<line x1="0" y1="48" x2="$_width" y2="48" stroke="#D7E2DB"/>',
      )
      ..write(content);

    if (redact) {
      buffer.writeln(
        '<text x="$_pad" y="${height - 10}" '
        'font-family="ui-sans-serif,system-ui,sans-serif" font-size="10" '
        'fill="#5A6B62">Redacted export</text>',
      );
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  String _docOpen(double height) {
    return '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<svg xmlns="http://www.w3.org/2000/svg" width="$_width" '
        'height="${height.toStringAsFixed(0)}" viewBox="0 0 $_width $height">\n';
  }

  String _brandHeader() {
    return '<rect width="100%" height="100%" fill="#F4F7F5"/>\n'
        '<text x="$_pad" y="36" font-family="ui-sans-serif,system-ui,sans-serif" '
        'font-size="20" font-weight="700" fill="#13201A">Ferret</text>';
  }

  String _emptyCard(double x, double y, double w, double h, String label) {
    return '''
<g>
  <rect x="$x" y="$y" width="$w" height="$h" rx="14" fill="#FFFFFF" stroke="#D7E2DB"/>
  <text x="${x + w / 2}" y="${y + h / 2}" text-anchor="middle"
    font-family="ui-sans-serif,system-ui,sans-serif" font-size="14" fill="#5A6B62">
    ${_esc(label)}
  </text>
</g>''';
  }

  String _summaryCard(
    FerretEntry entry, {
    required double x,
    required double y,
    required double width,
    required double height,
    required bool redact,
  }) {
    final failed = entry.isFailed;
    final accent = failed ? '#B3261E' : '#1B6B4A';
    final status = entry.statusCode?.toString() ??
        (entry.error != null ? 'ERR' : '…');
    final url = redact
        ? entry.url.replace(query: '').toString()
        : entry.url.toString();
    final ms = entry.duration?.inMilliseconds;
    final size = entry.sizeBytes;
    final body = _formatBody(entry.responseBody);
    final preview = body.isEmpty
        ? (entry.error?.trim().isNotEmpty == true
            ? entry.error!.trim()
            : '(no body)')
        : body;
    final clipped = _clip(preview, 160);

    return '''
<g>
  <rect x="$x" y="$y" width="$width" height="$height" rx="14" fill="#FFFFFF" stroke="#D7E2DB"/>
  <rect x="$x" y="$y" width="6" height="$height" rx="3" fill="$accent"/>
  <text x="${x + 22}" y="${y + 32}" font-family="ui-sans-serif,system-ui,sans-serif"
    font-size="15" font-weight="700" fill="$accent">${_esc(entry.method)}</text>
  <text x="${x + 92}" y="${y + 32}" font-family="ui-sans-serif,system-ui,sans-serif"
    font-size="15" font-weight="700" fill="${failed ? '#B3261E' : '#13201A'}">${_esc(status)}</text>
  <text x="${x + width - 18}" y="${y + 32}" text-anchor="end"
    font-family="ui-sans-serif,system-ui,sans-serif" font-size="12" fill="#5A6B62">${_esc(entry.client.name)}</text>
  <text x="${x + 22}" y="${y + 58}" font-family="ui-sans-serif,system-ui,sans-serif"
    font-size="13" fill="#13201A">${_esc(_clip(url, 78))}</text>
  <text x="${x + 22}" y="${y + 82}" font-family="ui-sans-serif,system-ui,sans-serif"
    font-size="12" fill="#5A6B62">${_esc(_meta(ms, size))}</text>
  <text x="${x + 22}" y="${y + 112}" font-family="ui-monospace,SFMono-Regular,Menlo,monospace"
    font-size="11" fill="#3A4A42">${_esc(clipped)}</text>
</g>''';
  }

  static List<String> _wrapHeader(String name, String value) {
    final first = '$name: $value';
    final lines = _wrap(first, _bodyChars);
    if (lines.length <= 1) return lines;
    // Keep continuation lines indented under the value column.
    final prefix = '$name: ';
    final out = <String>[lines.first];
    for (var i = 1; i < lines.length; i++) {
      out.add('${' ' * prefix.length}${lines[i]}');
    }
    return out;
  }

  static List<String> _wrap(String text, int maxChars) {
    if (text.isEmpty) return const [''];
    final out = <String>[];
    var remaining = text;
    while (remaining.length > maxChars) {
      var breakAt = remaining.lastIndexOf(' ', maxChars);
      if (breakAt < maxChars ~/ 3) breakAt = maxChars;
      out.add(remaining.substring(0, breakAt));
      remaining = remaining.substring(breakAt).trimLeft();
    }
    out.add(remaining);
    return out;
  }

  static List<String> _wrapPreserveNewlines(String text, int maxChars) {
    final out = <String>[];
    for (final paragraph in text.split('\n')) {
      out.addAll(_wrap(paragraph, maxChars));
    }
    return out;
  }

  static String _formatBody(Object? body) {
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

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _meta(int? ms, int? size) {
    final parts = <String>[];
    if (ms != null) parts.add('$ms ms');
    if (size != null) parts.add(_formatBytes(size));
    return parts.isEmpty ? 'timing unavailable' : parts.join(' · ');
  }

  static String _clip(String value, int maxChars) {
    final oneLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.length <= maxChars) return oneLine;
    return '${oneLine.substring(0, maxChars - 1)}…';
  }

  static bool _sensitiveHeader(String name) {
    final n = name.toLowerCase();
    return n.contains('authorization') ||
        n.contains('cookie') ||
        n.contains('token') ||
        n.contains('api-key') ||
        n.contains('x-api-key');
  }

  static String _esc(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _SvgBlock {
  const _SvgBlock._({
    this.text = '',
    this.size = 13,
    this.weight = 400,
    this.color = '#13201A',
    this.mono = false,
    this.center = false,
    this.indent = 0,
    this.gap = 0,
  });

  factory _SvgBlock.text(
    String text, {
    double size = 13,
    int weight = 400,
    String color = '#13201A',
    bool mono = false,
    bool center = false,
    double indent = 0,
  }) {
    return _SvgBlock._(
      text: text,
      size: size,
      weight: weight,
      color: color,
      mono: mono,
      center: center,
      indent: indent,
    );
  }

  factory _SvgBlock.gap(double gap) => _SvgBlock._(gap: gap);

  final String text;
  final double size;
  final int weight;
  final String color;
  final bool mono;
  final bool center;
  final double indent;
  final double gap;

  bool get isGap => gap > 0;
}
