import 'dart:convert';

import '../core/ferret_entry.dart';

/// Builds a cURL command from a [FerretEntry].
class CurlExporter {
  const CurlExporter();

  String export(FerretEntry entry, {bool redact = false}) {
    final headers = redact
        ? _redactHeaders(entry.requestHeaders)
        : entry.requestHeaders;

    final buffer = StringBuffer('curl -X ${entry.method}');
    buffer.write(' \'${_escape(entry.url.toString())}\'');

    headers.forEach((key, value) {
      buffer.write(' \\\n  -H \'${_escape('$key: $value')}\'');
    });

    final body = entry.requestBody;
    if (body != null) {
      final Object redactedOrRaw = redact ? _redactBody(body) : body;
      final payload = _stringifyBody(redactedOrRaw);
      if (payload.isNotEmpty) {
        buffer.write(' \\\n  --data-raw \'${_escape(payload)}\'');
      }
    }

    return buffer.toString();
  }

  static String _stringifyBody(Object body) {
    if (body is String) return body;
    if (body is List<int>) {
      try {
        return utf8.decode(body);
      } on Object {
        return base64Encode(body);
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } on Object {
      return body.toString();
    }
  }

  static String _escape(String value) =>
      value.replaceAll("'", r"'\''");

  static Map<String, String> _redactHeaders(Map<String, String> headers) {
    final out = <String, String>{};
    headers.forEach((key, value) {
      out[key] = _isSensitiveHeader(key) ? '***' : value;
    });
    return out;
  }

  static bool _isSensitiveHeader(String key) {
    final lower = key.toLowerCase();
    return lower == 'authorization' ||
        lower == 'proxy-authorization' ||
        lower == 'cookie' ||
        lower == 'set-cookie' ||
        lower.contains('token') ||
        lower.contains('api-key') ||
        lower.contains('apikey') ||
        lower.contains('secret');
  }

  static Object _redactBody(Object body) {
    if (body is Map) {
      return body.map((key, value) {
        final k = '$key'.toLowerCase();
        if (k.contains('password') ||
            k.contains('token') ||
            k.contains('secret') ||
            k.contains('email')) {
          return MapEntry(key, '***');
        }
        return MapEntry(key, value);
      });
    }
    if (body is String) {
      return body
          .replaceAll(
            RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
            '***@***',
          )
          .replaceAll(
            RegExp(r'(Bearer\s+)\S+', caseSensitive: false),
            r'$1***',
          );
    }
    return body;
  }
}
