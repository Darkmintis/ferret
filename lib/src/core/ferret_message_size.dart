import 'dart:convert';

/// Byte-size helpers for request/response sections in the inspector UI.
abstract final class FerretMessageSize {
  static int bytes({required Map<String, String> headers, Object? body}) {
    return _headersBytes(headers) + bodyBytes(body);
  }

  /// Headers plus the full body size: [originalBodySize] when the stored
  /// [body] was truncated, otherwise the size of [body] itself.
  static int messageBytes({
    required Map<String, String> headers,
    Object? body,
    int? originalBodySize,
  }) {
    return _headersBytes(headers) + (originalBodySize ?? bodyBytes(body));
  }

  static String? header(Map<String, String> headers, String name) {
    final target = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == target) {
        return entry.value;
      }
    }
    return null;
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static int _headersBytes(Map<String, String> headers) {
    var total = 0;
    headers.forEach((key, value) {
      total += key.length + value.length + 4;
    });
    return total;
  }

  /// UTF-8 size of a captured body (JSON-encoded for maps / lists).
  static int bodyBytes(Object? body) {
    if (body == null) return 0;
    if (body is List<int>) return body.length;
    if (body is String) return utf8.encode(body).length;
    try {
      return utf8.encode(jsonEncode(body)).length;
    } on Object {
      return utf8.encode(body.toString()).length;
    }
  }
}
