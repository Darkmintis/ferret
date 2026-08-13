import 'package:flutter/material.dart';

import '../core/ferret_entry.dart';
import '../export/share_exporter.dart';
import 'ferret_export_options.dart';
import 'ferret_ui_feedback.dart';

/// HAR export bottom sheet for a session or a single call.
abstract final class FerretExportSheet {
  static Future<void> showSession(
    BuildContext context, {
    required List<FerretEntry> entries,
  }) async {
    if (entries.isEmpty) {
      FerretUiFeedback.showError(context, 'Nothing to export');
      return;
    }

    await _show(
      context,
      title: 'Export session',
      subtitle: 'HAR · cURL per call from the list',
      onShareHar: (redact) =>
          const ShareExporter().shareSessionHar(entries, redact: redact),
      onCopyHar: (redact) =>
          const ShareExporter().copySessionHar(entries, redact: redact),
    );
  }

  static Future<void> showCall(
    BuildContext context, {
    required FerretEntry entry,
  }) async {
    await _show(
      context,
      title: 'Export call',
      subtitle: '${entry.method} ${entry.url.path}',
      onShareHar: (redact) =>
          const ShareExporter().shareEntryHar(entry, redact: redact),
      onCopyHar: (redact) =>
          const ShareExporter().copySessionHar([entry], redact: redact),
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Future<void> Function(bool redact) onShareHar,
    required Future<void> Function(bool redact) onCopyHar,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FerretExportOptions(
            title: title,
            subtitle: subtitle,
            parentContext: context,
            onShareHar: onShareHar,
            onCopyHar: onCopyHar,
          ),
        );
      },
    );
  }
}
