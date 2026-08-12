import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Web-safe share helpers (no `dart:io`).
Future<ShareResult> ferretShareTextFile({
  required String content,
  required String filename,
  required String mime,
  required String subject,
  String? text,
}) {
  final bytes = Uint8List.fromList(utf8.encode(content));
  return SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: mime,
          name: filename,
        ),
      ],
      subject: subject,
      text: text,
    ),
  );
}

Future<ShareResult> ferretSharePlainText({
  required String text,
  required String subject,
}) {
  return SharePlus.instance.share(
    ShareParams(text: text, subject: subject),
  );
}
