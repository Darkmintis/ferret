import 'dart:convert';
import 'dart:math';

import '../config/ferret_config.dart';
import '../config/http_client_type.dart';
import 'ferret_entry.dart';
import 'ferret_store.dart';

/// Capture pipeline: creates entries, sizes bodies, completes requests.
class FerretEngine {
  FerretEngine({
    required FerretStore store,
    required FerretConfig config,
  })  : _store = store,
        _config = config;

  final FerretStore _store;
  FerretConfig _config;
  final Random _random = Random();

  FerretConfig get config => _config;

  FerretStore get store => _store;

  void updateConfig(FerretConfig config) {
    _config = config;
    _store.setMaxEntries(config.maxEntries);
  }

  /// Whether this engine should capture for [client].
  bool accepts(HttpClientType client) => _config.clients.contains(client);

  String nextId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final suffix = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '${millis}_$suffix';
  }

  FerretEntry begin({
    required HttpClientType client,
    required String method,
    required Uri url,
    Map<String, String> requestHeaders = const {},
    Object? requestBody,
    DateTime? startTime,
  }) {
    final entry = FerretEntry(
      id: nextId(),
      client: client,
      method: method.toUpperCase(),
      url: url,
      requestHeaders: Map<String, String>.unmodifiable(requestHeaders),
      requestBody: _config.captureBody ? _normalizeBody(requestBody) : null,
      startTime: startTime ?? DateTime.now(),
    );
    _store.add(entry);
    return entry;
  }

  void complete({
    required String id,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Object? responseBody,
    String? error,
    DateTime? endTime,
  }) {
    final ended = endTime ?? DateTime.now();
    _store.update(id, (current) {
      final body = _config.captureBody ? _normalizeBody(responseBody) : null;
      return current.copyWith(
        statusCode: statusCode,
        responseHeaders: responseHeaders == null
            ? current.responseHeaders
            : Map<String, String>.unmodifiable(responseHeaders),
        responseBody: body ?? current.responseBody,
        endTime: ended,
        sizeBytes: _estimateSize(
          requestHeaders: current.requestHeaders,
          requestBody: current.requestBody,
          responseHeaders: responseHeaders ?? current.responseHeaders,
          responseBody: body ?? current.responseBody,
        ),
        error: error,
        clearError: error == null,
      );
    });
  }

  void fail(String id, Object error, [StackTrace? stackTrace]) {
    complete(
      id: id,
      error: stackTrace == null ? '$error' : '$error\n$stackTrace',
    );
  }

  static Object? _normalizeBody(Object? body) {
    if (body == null) return null;
    if (body is String || body is List<int> || body is Map || body is List) {
      return body;
    }
    return body.toString();
  }

  static int _estimateSize({
    required Map<String, String> requestHeaders,
    required Object? requestBody,
    required Map<String, String>? responseHeaders,
    required Object? responseBody,
  }) {
    var total = 0;
    total += _headersBytes(requestHeaders);
    total += _bodyBytes(requestBody);
    if (responseHeaders != null) {
      total += _headersBytes(responseHeaders);
    }
    total += _bodyBytes(responseBody);
    return total;
  }

  static int _headersBytes(Map<String, String> headers) {
    var n = 0;
    headers.forEach((k, v) {
      n += k.length + v.length + 4;
    });
    return n;
  }

  static int _bodyBytes(Object? body) {
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
