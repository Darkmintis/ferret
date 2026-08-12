import 'dart:convert';

import 'package:ferret/ferret.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_entries.dart';

void main() {
  group('CurlExporter', () {
    test('builds redacted curl without secrets', () {
      final curl = const CurlExporter().export(
        testEntry(
          '1',
          method: 'POST',
          requestHeaders: const {
            'Authorization': 'Bearer secret',
            'X-Api-Key': 'key-123',
            'Cookie': 'sid=abc',
            'Accept': 'application/json',
          },
          requestBody: {
            'password': 'hunter2',
            'email': 'a@b.com',
            'name': 'Ada',
          },
        ),
        redact: true,
      );
      expect(curl, contains('curl -X POST'));
      expect(curl, contains('***'));
      expect(curl, isNot(contains('Bearer secret')));
      expect(curl, isNot(contains('key-123')));
      expect(curl, isNot(contains('hunter2')));
      expect(curl, contains('Accept: application/json'));
    });

    test('escapes single quotes in url', () {
      final curl = const CurlExporter().export(
        testEntry('q', url: Uri.parse("https://example.com/path?q=it's")),
      );
      expect(curl, contains(r"'\''"));
    });

    test('string body bearer redaction', () {
      final curl = const CurlExporter().export(
        testEntry(
          '1',
          method: 'POST',
          requestBody: 'Authorization: Bearer tok_live_123',
        ),
        redact: true,
      );
      expect(curl, contains('Bearer ***'));
      expect(curl, isNot(contains('tok_live_123')));
    });

    test('omits empty body', () {
      final curl = const CurlExporter().export(testEntry('1', requestBody: ''));
      expect(curl, isNot(contains('--data-raw')));
    });

    test('encodes binary body as utf8 or base64', () {
      final utf = const CurlExporter().export(
        testEntry('1', method: 'POST', requestBody: utf8.encode('hi')),
      );
      expect(utf, contains('--data-raw'));
      expect(utf, contains('hi'));
    });
  });

  group('HarExporter', () {
    test('builds valid HAR 1.2 with sorted entries', () {
      final early = completedEntry('a').copyWith(
        startTime: DateTime.utc(2026, 1, 1, 10),
        endTime: DateTime.utc(2026, 1, 1, 10, 0, 1),
      );
      final late = completedEntry('b').copyWith(
        startTime: DateTime.utc(2026, 1, 1, 11),
        endTime: DateTime.utc(2026, 1, 1, 11, 0, 1),
      );
      final har =
          jsonDecode(const HarExporter().export([late, early]))
              as Map<String, dynamic>;
      final log = har['log'] as Map<String, dynamic>;
      expect(log['version'], '1.2');
      expect((log['creator'] as Map)['name'], 'ferret');
      final entries = log['entries'] as List<dynamic>;
      expect(entries, hasLength(2));
      expect(
        (entries[0] as Map)['startedDateTime'].toString().startsWith(
          '2026-01-01T10',
        ),
        isTrue,
      );
    });

    test('pending calls use status 0', () {
      final har =
          jsonDecode(const HarExporter().export([testEntry('p', status: null)]))
              as Map<String, dynamic>;
      final entry =
          ((har['log'] as Map)['entries'] as List).first
              as Map<String, dynamic>;
      expect((entry['response'] as Map)['status'], 0);
    });

    test('includes queryString and redacts sensitive headers', () {
      final har =
          jsonDecode(
                const HarExporter().export([
                  completedEntry(
                    '1',
                    requestHeaders: const {
                      'Authorization': 'Bearer x',
                      'content-type': 'application/json',
                    },
                    requestBody: {'token': 'secret', 'ok': true},
                    responseBody: {'email': 'a@b.com', 'ok': true},
                    responseHeaders: const {'set-cookie': 'session=abc'},
                  ).copyWith(
                    url: Uri.parse(
                      'https://example.com/search?q=ferret&token=abc&page=1',
                    ),
                  ),
                ], redact: true),
              )
              as Map<String, dynamic>;
      final entry =
          ((har['log'] as Map)['entries'] as List).first
              as Map<String, dynamic>;
      final request = entry['request'] as Map<String, dynamic>;
      final headers = request['headers'] as List<dynamic>;
      final auth = headers.cast<Map<Object?, Object?>>().firstWhere(
        (h) => h['name'] == 'Authorization',
      );
      expect(auth['value'], '***');
      final query = request['queryString'] as List<dynamic>;
      expect(query, hasLength(3));
      final token = query.cast<Map<Object?, Object?>>().firstWhere(
        (q) => q['name'] == 'token',
      );
      expect(token['value'], '***');
      final post = request['postData'] as Map<String, dynamic>;
      expect(post['text'], contains('***'));
      expect(post['text'], isNot(contains('secret')));
      final response = entry['response'] as Map<String, dynamic>;
      final responseHeaders = response['headers'] as List<dynamic>;
      final cookie = responseHeaders.cast<Map<Object?, Object?>>().firstWhere(
        (h) => h['name'] == 'set-cookie',
      );
      expect(cookie['value'], '***');
      final content = response['content'] as Map<String, dynamic>;
      expect(content['text'], contains('***'));
      expect(content['text'], isNot(contains('a@b.com')));
    });

    test('empty session exports empty entries array', () {
      final har =
          jsonDecode(const HarExporter().export(const []))
              as Map<String, dynamic>;
      expect((har['log'] as Map)['entries'], isEmpty);
    });
  });
}
