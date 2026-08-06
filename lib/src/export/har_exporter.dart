import 'dart:convert';

import '../core/ferret_entry.dart';

/// Exports captured calls as HAR 1.2 JSON.
class HarExporter {
  const HarExporter();

  String export(
    List<FerretEntry> entries, {
    bool redact = false,
    String creatorName = 'ferret',
    String creatorVersion = '0.1.0',
  }) {
    final sorted = [...entries]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final log = <String, Object?>{
      'log': {
        'version': '1.2',
        'creator': {
          'name': creatorName,
          'version': creatorVersion,
        },
        'entries': [
          for (final entry in sorted) _toHarEntry(entry, redact: redact),
        ],
      },
    };

    return const JsonEncoder.withIndent('  ').convert(log);
  }

  Map<String, Object?> _toHarEntry(FerretEntry entry, {required bool redact}) {
    final headers = redact
        ? _redactHeaders(entry.requestHeaders)
        : entry.requestHeaders;
    final responseHeaders = redact
        ? _redactHeaders(entry.responseHeaders ?? const {})
        : (entry.responseHeaders ?? const {});

    final started = entry.startTime.toUtc().toIso8601String();
    final time = entry.duration?.inMilliseconds ?? 0;
    final body = entry.requestBody;
    final responseBody = entry.responseBody;

    return {
      'startedDateTime': started,
      'time': time,
      'request': {
        'method': entry.method,
        'url': entry.url.toString(),
        'httpVersion': 'HTTP/1.1',
        'cookies': <Object?>[],
        'headers': [
          for (final e in headers.entries)
            {'name': e.key, 'value': e.value},
        ],
        'queryString': [
          for (final e in entry.url.queryParameters.entries)
            {'name': e.key, 'value': e.value},
        ],
        'headersSize': -1,
        'bodySize': _bodySize(body),
        if (body != null)
          'postData': {
            'mimeType': headers['content-type'] ??
                headers['Content-Type'] ??
                'application/json',
            'text': _stringifyBody(redact ? _redactBody(body) : body),
          },
      },
      'response': {
        'status': entry.statusCode ?? 0,
        'statusText': entry.error ?? '',
        'httpVersion': 'HTTP/1.1',
        'cookies': <Object?>[],
        'headers': [
          for (final e in responseHeaders.entries)
            {'name': e.key, 'value': e.value},
        ],
        'content': {
          'size': _bodySize(responseBody),
          'mimeType': responseHeaders['content-type'] ??
              responseHeaders['Content-Type'] ??
              'application/octet-stream',
          'text': responseBody == null ? '' : _stringifyBody(responseBody),
        },
        'redirectURL': '',
        'headersSize': -1,
        'bodySize': _bodySize(responseBody),
      },
      'cache': <String, Object?>{},
      'timings': {
        'send': 0,
        'wait': time,
        'receive': 0,
      },
    };
  }

  static Map<String, String> _redactHeaders(Map<String, String> headers) {
    final out = <String, String>{};
    headers.forEach((key, value) {
      final lower = key.toLowerCase();
      final sensitive = lower == 'authorization' ||
          lower == 'cookie' ||
          lower == 'set-cookie' ||
          lower.contains('token') ||
          lower.contains('api-key');
      out[key] = sensitive ? '***' : value;
    });
    return out;
  }

  static int _bodySize(Object? body) {
    if (body == null) return 0;
    if (body is List<int>) return body.length;
    return utf8.encode(_stringifyBody(body)).length;
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
      return jsonEncode(body);
    } on Object {
      return body.toString();
    }
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
      return body.replaceAll(
        RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
        '***@***',
      );
    }
    return body;
  }
}
