import 'package:flutter/services.dart';

import '../core/ferret_entry.dart';
import 'curl_exporter.dart';
import 'har_exporter.dart';
import 'share_platform.dart';

/// Shares captured calls as cURL or HAR.
class ShareExporter {
  const ShareExporter({
    this.harExporter = const HarExporter(),
    this.curlExporter = const CurlExporter(),
  });

  final HarExporter harExporter;
  final CurlExporter curlExporter;

  /// Share the full session as HAR.
  Future<void> shareSessionHar(
    List<FerretEntry> entries, {
    bool redact = false,
  }) {
    final content = harExporter.export(entries, redact: redact);
    return ferretShareTextFile(
      content: content,
      filename: 'ferret-session.har',
      mime: 'application/json',
      subject: 'Ferret session',
    );
  }

  /// Share one call as HAR.
  Future<void> shareEntryHar(FerretEntry entry, {bool redact = false}) {
    final content = harExporter.export([entry], redact: redact);
    return ferretShareTextFile(
      content: content,
      filename: 'ferret-call.har',
      mime: 'application/json',
      subject: 'Ferret call · ${entry.method} ${entry.statusCode ?? ''}'.trim(),
    );
  }

  /// Share one call as cURL.
  Future<void> shareCurl(FerretEntry entry, {bool redact = false}) {
    final curl = curlExporter.export(entry, redact: redact);
    return ferretSharePlainText(text: curl, subject: 'Ferret cURL');
  }

  /// Copy session HAR to the clipboard.
  Future<void> copySessionHar(
    List<FerretEntry> entries, {
    bool redact = false,
  }) async {
    final content = harExporter.export(entries, redact: redact);
    await Clipboard.setData(ClipboardData(text: content));
  }
}
