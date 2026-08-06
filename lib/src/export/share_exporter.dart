import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/ferret_entry.dart';
import 'har_exporter.dart';

/// Shares a session file (HAR) via the platform share sheet.
class ShareExporter {
  const ShareExporter({this.harExporter = const HarExporter()});

  final HarExporter harExporter;

  Future<ShareResult> shareSession(
    List<FerretEntry> entries, {
    bool redact = false,
    String filename = 'ferret-session.har',
  }) async {
    final json = harExporter.export(entries, redact: redact);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json);
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Ferret session',
      ),
    );
  }
}
