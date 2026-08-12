import 'dart:convert';

import '../core/ferret_entry.dart';
import 'ferret_redaction.dart';

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
        'creator': {'name': creatorName, 'version': creatorVersion},
        'entries': [
          for (final entry in sorted) _toHarEntry(entry, redact: redact),
        ],
      },
    };

    return const JsonEncoder.withIndent('  ').convert(log);
  }

  Map<String, Object?> _toHarEntry(FerretEntry entry, {required bool redact}) {
    final headers = redact
        ? FerretRedaction.headers(entry.requestHeaders)
        : entry.requestHeaders;
    final responseHeaders = redact
        ? FerretRedaction.headers(entry.responseHeaders ?? const {})
        : (entry.responseHeaders ?? const {});

    final started = entry.startTime.toUtc().toIso8601String();
    final time = entry.duration?.inMilliseconds ?? 0;
    final body = entry.requestBody;
    final responseBody = entry.responseBody;
    final url = redact ? FerretRedaction.url(entry.url) : entry.url;
    final query = redact
        ? FerretRedaction.queryParameters(entry.url.queryParameters)
        : entry.url.queryParameters;

    return {
      'startedDateTime': started,
      'time': time,
      'request': {
        'method': entry.method,
        'url': url.toString(),
        'httpVersion': 'HTTP/1.1',
        'cookies': <Object?>[],
        'headers': [
          for (final e in headers.entries) {'name': e.key, 'value': e.value},
        ],
        'queryString': [
          for (final e in query.entries) {'name': e.key, 'value': e.value},
        ],
        'headersSize': -1,
        'bodySize': _bodySize(body),
        if (body != null)
          'postData': {
            'mimeType':
                headers['content-type'] ??
                headers['Content-Type'] ??
                'application/json',
            'text': FerretRedaction.stringifyBody(
              redact ? FerretRedaction.body(body) : body,
            ),
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
          'mimeType':
              responseHeaders['content-type'] ??
              responseHeaders['Content-Type'] ??
              'application/octet-stream',
          'text': responseBody == null
              ? ''
              : FerretRedaction.stringifyBody(
                  redact ? FerretRedaction.body(responseBody) : responseBody,
                ),
        },
        'redirectURL': '',
        'headersSize': -1,
        'bodySize': _bodySize(responseBody),
      },
      'cache': <String, Object?>{},
      'timings': {'send': 0, 'wait': time, 'receive': 0},
    };
  }

  static int _bodySize(Object? body) {
    if (body == null) return 0;
    if (body is List<int>) return body.length;
    return utf8.encode(FerretRedaction.stringifyBody(body)).length;
  }
}
