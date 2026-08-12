import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web / WASM-safe share helpers (no `dart:io`, no `share_plus`).
Future<void> ferretShareTextFile({
  required String content,
  required String filename,
  required String mime,
  required String subject,
  String? text,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  await _shareBlob(
    blob: blob,
    filename: filename,
    subject: subject,
    text: text,
    mime: mime,
  );
}

Future<void> ferretSharePlainText({
  required String text,
  required String subject,
}) async {
  final data = web.ShareData(title: subject, text: text);
  if (web.window.navigator.canShare(data)) {
    await web.window.navigator.share(data).toDart;
    return;
  }
  await web.window.navigator.clipboard.writeText(text).toDart;
}

Future<void> _shareBlob({
  required web.Blob blob,
  required String filename,
  required String subject,
  required String? text,
  required String mime,
}) async {
  try {
    final file = web.File(
      <web.Blob>[blob].toJS,
      filename,
      web.FilePropertyBag(type: mime),
    );
    final data = web.ShareData(
      files: <web.File>[file].toJS,
      title: subject,
      text: text ?? '',
    );
    if (web.window.navigator.canShare(data)) {
      await web.window.navigator.share(data).toDart;
      return;
    }
  } on Object {
    // Fall back to a direct download when the Web Share API is unavailable.
  }

  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
