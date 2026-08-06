import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../core/ferret_entry.dart';
import '../core/ferret_store.dart';
import '../export/har_exporter.dart';

/// Simple LAN mirror: open the printed URL on a desktop browser to view traffic.
class FerretMirrorServer {
  FerretMirrorServer(this._store);

  final FerretStore _store;
  HttpServer? _server;

  bool get isRunning => _server != null;

  int? get port => _server?.port;

  Future<Uri> start({int port = 7474}) async {
    if (_server != null) {
      return Uri.parse('http://127.0.0.1:${_server!.port}/');
    }

    final router = Router()
      ..get('/', _htmlHandler)
      ..get('/api/entries', _jsonHandler)
      ..get('/api/har', _harHandler);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    return Uri.parse('http://127.0.0.1:${_server!.port}/');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Response _jsonHandler(Request request) {
    final payload = [
      for (final e in _store.entries) _entryJson(e),
    ];
    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json'},
    );
  }

  Response _harHandler(Request request) {
    final har = const HarExporter().export(_store.entries);
    return Response.ok(
      har,
      headers: {'content-type': 'application/json'},
    );
  }

  Response _htmlHandler(Request request) {
    final rows = _store.entries.map((e) {
      final status = e.statusCode?.toString() ?? e.error ?? '…';
      final ms = e.duration?.inMilliseconds;
      return '<tr>'
          '<td>${e.method}</td>'
          '<td>${_escape(e.url.toString())}</td>'
          '<td>$status</td>'
          '<td>${ms == null ? '…' : '$ms ms'}</td>'
          '</tr>';
    }).join();

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta http-equiv="refresh" content="2"/>
  <title>Ferret Mirror</title>
  <style>
    body { font-family: ui-sans-serif, system-ui, sans-serif; margin: 24px; background: #0f1115; color: #e8eaed; }
    h1 { font-weight: 600; letter-spacing: -0.02em; }
    a { color: #7dd3fc; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #2a2f3a; font-size: 13px; }
    th { color: #9aa0a6; font-weight: 500; }
    code { background: #1a1f29; padding: 2px 6px; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>Ferret</h1>
  <p>Live mirror · auto-refresh 2s · <a href="/api/entries">JSON</a> · <a href="/api/har">HAR</a></p>
  <table>
    <thead><tr><th>Method</th><th>URL</th><th>Status</th><th>Time</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
</body>
</html>
''';
    return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
  }

  static Map<String, Object?> _entryJson(FerretEntry e) {
    return {
      'id': e.id,
      'client': e.client.name,
      'method': e.method,
      'url': e.url.toString(),
      'statusCode': e.statusCode,
      'durationMs': e.duration?.inMilliseconds,
      'error': e.error,
      'startTime': e.startTime.toIso8601String(),
    };
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
