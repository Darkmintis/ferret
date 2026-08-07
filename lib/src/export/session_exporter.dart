import 'dart:convert';

import '../config/ferret_config.dart';
import '../core/ferret_entry.dart';
import '../core/ferret_stats.dart';

/// Export formats for sharing a captured session.
enum FerretExportFormat {
  /// HTTP Archive 1.2 (Chrome DevTools compatible).
  har,

  /// Compact JSON list of calls (id, method, url, status, timing).
  json,

  /// Human-readable plain text summary.
  text,

  /// Markdown report for chats / docs.
  markdown,
}

/// Builds session exports in multiple formats.
class SessionExporter {
  const SessionExporter();

  String export(
    List<FerretEntry> entries, {
    required FerretExportFormat format,
    required FerretConfig config,
    bool redact = false,
  }) {
    switch (format) {
      case FerretExportFormat.har:
        // Delegated by ShareExporter / HarExporter callers for HAR body.
        throw UnsupportedError('Use HarExporter for HAR');
      case FerretExportFormat.json:
        return _json(entries, config: config);
      case FerretExportFormat.text:
        return _text(entries, config: config, redact: redact);
      case FerretExportFormat.markdown:
        return _markdown(entries, config: config, redact: redact);
    }
  }

  String _json(List<FerretEntry> entries, {required FerretConfig config}) {
    final stats = FerretStats.fromEntries(
      entries,
      slowThreshold: config.slowThreshold,
    );
    final payload = <String, Object?>{
      'generator': 'ferret',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'stats': {
        'total': stats.total,
        'failed': stats.failed,
        'slow': stats.slow,
        'pending': stats.pending,
      },
      'entries': [
        for (final e in entries)
          {
            'id': e.id,
            'client': e.client.name,
            'method': e.method,
            'url': e.url.toString(),
            'statusCode': e.statusCode,
            'durationMs': e.duration?.inMilliseconds,
            'sizeBytes': e.sizeBytes,
            'error': e.error,
            'failed': e.isFailed,
            'startTime': e.startTime.toIso8601String(),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _text(
    List<FerretEntry> entries, {
    required FerretConfig config,
    required bool redact,
  }) {
    final stats = FerretStats.fromEntries(
      entries,
      slowThreshold: config.slowThreshold,
    );
    final buffer = StringBuffer()
      ..writeln('Ferret session')
      ..writeln(stats.statusLine)
      ..writeln('Exported: ${DateTime.now().toIso8601String()}')
      ..writeln(List.filled(48, '-').join());

    for (final e in entries) {
      final status = e.statusCode?.toString() ?? e.error ?? 'pending';
      final ms = e.duration?.inMilliseconds;
      buffer.writeln(
        '${e.method.padRight(6)} $status  '
        '${ms == null ? '…'.padLeft(6) : '${ms}ms'.padLeft(6)}  '
        '${redact ? e.url.replace(query: '') : e.url}',
      );
    }
    return buffer.toString();
  }

  String _markdown(
    List<FerretEntry> entries, {
    required FerretConfig config,
    required bool redact,
  }) {
    final stats = FerretStats.fromEntries(
      entries,
      slowThreshold: config.slowThreshold,
    );
    final buffer = StringBuffer()
      ..writeln('# Ferret session')
      ..writeln()
      ..writeln(stats.statusLine)
      ..writeln()
      ..writeln('| Method | Status | Time | URL |')
      ..writeln('| --- | --- | --- | --- |');

    for (final e in entries) {
      final status = e.statusCode?.toString() ?? e.error ?? '…';
      final ms = e.duration?.inMilliseconds;
      final url = redact ? e.url.replace(query: '') : e.url;
      buffer.writeln(
        '| `${e.method}` | $status | ${ms == null ? '…' : '$ms ms'} | `$url` |',
      );
    }
    return buffer.toString();
  }
}
