import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// VM / mobile share helpers using `dart:io`.
Future<void> ferretShareTextFile({
  required String content,
  required String filename,
  required String mime,
  required String subject,
  String? text,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(utf8.encode(content), flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mime)],
      subject: subject,
      text: text,
    ),
  );
}

Future<void> ferretSharePlainText({
  required String text,
  required String subject,
}) {
  return SharePlus.instance.share(ShareParams(text: text, subject: subject));
}
