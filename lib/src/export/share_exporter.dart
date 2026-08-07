import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/ferret_config.dart';
import '../core/ferret_entry.dart';
import 'curl_exporter.dart';
import 'har_exporter.dart';
import 'session_exporter.dart';

/// Shares or copies a session in HAR / JSON / text / Markdown formats.
class ShareExporter {
  const ShareExporter({
    this.harExporter = const HarExporter(),
    this.sessionExporter = const SessionExporter(),
    this.curlExporter = const CurlExporter(),
  });

  final HarExporter harExporter;
  final SessionExporter sessionExporter;
  final CurlExporter curlExporter;

  /// Share the full session via the platform share sheet.
  Future<ShareResult> shareSession(
    List<FerretEntry> entries, {
    required FerretConfig config,
    FerretExportFormat format = FerretExportFormat.har,
    bool redact = false,
  }) async {
    final content = _body(entries, config: config, format: format, redact: redact);
    final filename = _filename(format);
    final mime = _mime(format);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        subject: 'Ferret session',
        text: format == FerretExportFormat.text ||
                format == FerretExportFormat.markdown
            ? content
            : null,
      ),
    );
  }

  /// Copy export text to the clipboard.
  Future<void> copySession(
    List<FerretEntry> entries, {
    required FerretConfig config,
    FerretExportFormat format = FerretExportFormat.har,
    bool redact = false,
  }) async {
    final content = _body(entries, config: config, format: format, redact: redact);
    await Clipboard.setData(ClipboardData(text: content));
  }

  /// Share a single entry as cURL.
  Future<ShareResult> shareCurl(
    FerretEntry entry, {
    bool redact = false,
  }) {
    final curl = curlExporter.export(entry, redact: redact);
    return SharePlus.instance.share(
      ShareParams(text: curl, subject: 'Ferret cURL'),
    );
  }

  String _body(
    List<FerretEntry> entries, {
    required FerretConfig config,
    required FerretExportFormat format,
    required bool redact,
  }) {
    switch (format) {
      case FerretExportFormat.har:
        return harExporter.export(entries, redact: redact);
      case FerretExportFormat.json:
      case FerretExportFormat.text:
      case FerretExportFormat.markdown:
        return sessionExporter.export(
          entries,
          format: format,
          config: config,
          redact: redact,
        );
    }
  }

  static String _filename(FerretExportFormat format) {
    switch (format) {
      case FerretExportFormat.har:
        return 'ferret-session.har';
      case FerretExportFormat.json:
        return 'ferret-session.json';
      case FerretExportFormat.text:
        return 'ferret-session.txt';
      case FerretExportFormat.markdown:
        return 'ferret-session.md';
    }
  }

  static String _mime(FerretExportFormat format) {
    switch (format) {
      case FerretExportFormat.har:
      case FerretExportFormat.json:
        return 'application/json';
      case FerretExportFormat.text:
        return 'text/plain';
      case FerretExportFormat.markdown:
        return 'text/markdown';
    }
  }
}
