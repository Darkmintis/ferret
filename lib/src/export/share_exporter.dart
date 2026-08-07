import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/ferret_config.dart';
import '../core/ferret_entry.dart';
import 'curl_exporter.dart';
import 'har_exporter.dart';
import 'session_exporter.dart';
import 'svg_exporter.dart';

/// Shares, copies, or saves a session / single call.
class ShareExporter {
  const ShareExporter({
    this.harExporter = const HarExporter(),
    this.sessionExporter = const SessionExporter(),
    this.curlExporter = const CurlExporter(),
    this.svgExporter = const SvgExporter(),
  });

  final HarExporter harExporter;
  final SessionExporter sessionExporter;
  final CurlExporter curlExporter;
  final SvgExporter svgExporter;

  /// Share the full session via the platform share sheet.
  Future<ShareResult> shareSession(
    List<FerretEntry> entries, {
    required FerretConfig config,
    FerretExportFormat format = FerretExportFormat.har,
    bool redact = false,
  }) {
    final content =
        _body(entries, config: config, format: format, redact: redact);
    return _shareTextFile(
      content: content,
      filename: _filename(format, single: false),
      mime: _mime(format),
      subject: 'Ferret session',
      text: format == FerretExportFormat.text ||
              format == FerretExportFormat.markdown
          ? content
          : null,
    );
  }

  /// Share one captured call.
  Future<ShareResult> shareEntry(
    FerretEntry entry, {
    required FerretConfig config,
    FerretExportFormat format = FerretExportFormat.json,
    FerretSvgPane pane = FerretSvgPane.overview,
    bool redact = false,
  }) {
    final content = _entryBody(
      entry,
      config: config,
      format: format,
      pane: pane,
      redact: redact,
    );
    final subject =
        'Ferret call · ${entry.method} ${entry.statusCode ?? ''}'.trim();
    return _shareTextFile(
      content: content,
      filename: format == FerretExportFormat.svg
          ? 'ferret-call-${pane.name}.svg'
          : _filename(format, single: true),
      mime: _mime(format),
      subject: subject,
      text: format == FerretExportFormat.text ||
              format == FerretExportFormat.markdown
          ? content
          : null,
    );
  }

  /// Save the current detail tab as a `.svg` file. Returns the absolute path.
  Future<String> saveEntrySvg(
    FerretEntry entry, {
    FerretSvgPane pane = FerretSvgPane.overview,
    bool redact = false,
  }) async {
    final content = svgExporter.exportEntry(
      entry,
      pane: pane,
      redact: redact,
    );
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    return _saveSvgFile(
      content: content,
      filename: 'ferret-${pane.name}-$stamp.svg',
    );
  }

  /// Save session SVG cards. Returns the absolute path.
  Future<String> saveSessionSvg(
    List<FerretEntry> entries, {
    bool redact = false,
  }) async {
    final content = svgExporter.export(entries, redact: redact);
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    return _saveSvgFile(
      content: content,
      filename: 'ferret-session-$stamp.svg',
    );
  }

  Future<String> _saveSvgFile({
    required String content,
    required String filename,
  }) async {
    final dir = await _exportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(utf8.encode(content), flush: true);
    return file.path;
  }

  Future<Directory> _exportDirectory() async {
    if (Platform.isAndroid) {
      final download = Directory('/storage/emulated/0/Download/Ferret');
      if (await _canWrite(download)) return download;
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final ferret = Directory('${ext.path}/Ferret');
        if (await _canWrite(ferret)) return ferret;
      }
    }

    if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      return Directory('${docs.path}/Ferret');
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        final ferret = Directory('${downloads.path}/Ferret');
        if (await _canWrite(ferret)) return ferret;
      }
    } on Object {
      // Unsupported.
    }

    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/Ferret');
  }

  Future<bool> _canWrite(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final probe = File('${dir.path}/.ferret_write_probe');
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } on Object {
      return false;
    }
  }

  Future<ShareResult> _shareTextFile({
    required String content,
    required String filename,
    required String mime,
    required String subject,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        subject: subject,
        text: text,
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
    final content =
        _body(entries, config: config, format: format, redact: redact);
    await Clipboard.setData(ClipboardData(text: content));
  }

  /// Copy one call export to the clipboard.
  Future<void> copyEntry(
    FerretEntry entry, {
    required FerretConfig config,
    FerretExportFormat format = FerretExportFormat.json,
    FerretSvgPane pane = FerretSvgPane.overview,
    bool redact = false,
  }) async {
    final content = _entryBody(
      entry,
      config: config,
      format: format,
      pane: pane,
      redact: redact,
    );
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
      case FerretExportFormat.svg:
        return svgExporter.export(entries, redact: redact);
    }
  }

  String _entryBody(
    FerretEntry entry, {
    required FerretConfig config,
    required FerretExportFormat format,
    required FerretSvgPane pane,
    required bool redact,
  }) {
    switch (format) {
      case FerretExportFormat.har:
        return harExporter.export([entry], redact: redact);
      case FerretExportFormat.json:
      case FerretExportFormat.text:
      case FerretExportFormat.markdown:
        return sessionExporter.export(
          [entry],
          format: format,
          config: config,
          redact: redact,
        );
      case FerretExportFormat.svg:
        return svgExporter.exportEntry(entry, pane: pane, redact: redact);
    }
  }

  static String _filename(FerretExportFormat format, {required bool single}) {
    final prefix = single ? 'ferret-call' : 'ferret-session';
    switch (format) {
      case FerretExportFormat.har:
        return '$prefix.har';
      case FerretExportFormat.json:
        return '$prefix.json';
      case FerretExportFormat.text:
        return '$prefix.txt';
      case FerretExportFormat.markdown:
        return '$prefix.md';
      case FerretExportFormat.svg:
        return '$prefix.svg';
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
      case FerretExportFormat.svg:
        return 'text/xml';
    }
  }
}
