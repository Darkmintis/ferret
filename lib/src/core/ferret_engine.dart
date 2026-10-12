import 'dart:convert';
import 'dart:math';

import '../config/ferret_config.dart';
import '../config/http_client_type.dart';
import 'ferret_entry.dart';
import 'ferret_links.dart';
import 'ferret_message_size.dart';
import 'ferret_store.dart';

/// A body as stored on an entry: possibly truncated to
/// `FerretConfig.maxBodyBytes`, with the full size kept when it was.
typedef FerretCapturedBody = ({Object? body, int? originalSize});

/// Capture pipeline: creates entries, sizes bodies, completes requests.
class FerretEngine {
  FerretEngine({required FerretStore store, required FerretConfig config})
    : _store = store,
      _config = config;

  final FerretStore _store;
  FerretConfig _config;
  final Random _random = Random();

  /// Media-URL requests skipped at [begin]; dropped again if a non-media URL
  /// responds with `image/*` / `video/*`.
  final Set<String> _mediaSkipIds = <String>{};

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
    final mediaUrl = FerretLinks.isMediaUrl(url.toString());
    final captured = captureBody(
      requestBody,
      contentType: FerretMessageSize.header(requestHeaders, 'content-type'),
      url: url,
    );
    final entry = FerretEntry(
      id: nextId(),
      client: client,
      method: method.toUpperCase(),
      url: url,
      requestHeaders: Map<String, String>.unmodifiable(requestHeaders),
      requestBody: captured.body,
      requestBodyOriginalSize: captured.originalSize,
      startTime: startTime ?? DateTime.now(),
    );
    // Image/video URLs (and Ferret's own NetworkImage previews) stay off the
    // home list — Alice-style. Media still previews inside JSON API calls.
    if (mediaUrl) {
      _mediaSkipIds.add(entry.id);
    } else {
      _store.add(entry);
    }
    return entry;
  }

  /// Sets the request body after [begin] (streamed `dart:io` requests).
  void setRequestBody(String id, Object? body) {
    if (_mediaSkipIds.contains(id) || _store.getById(id) == null) return;
    final current = _store.getById(id)!;
    final captured = captureBody(
      body,
      contentType: FerretMessageSize.header(
        current.requestHeaders,
        'content-type',
      ),
      url: current.url,
    );
    if (captured.body == null) return;
    _store.update(
      id,
      (entry) => entry.copyWith(
        requestBody: captured.body,
        requestBodyOriginalSize: captured.originalSize,
      ),
    );
  }

  void complete({
    required String id,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Object? responseBody,
    String? error,
    DateTime? endTime,
  }) {
    if (_mediaSkipIds.remove(id)) return;

    final current = _store.getById(id);
    if (current == null) return;

    final headers = responseHeaders ?? current.responseHeaders ?? const {};
    final contentType = FerretMessageSize.header(headers, 'content-type');
    if (FerretLinks.isMediaContentType(contentType)) {
      _store.remove(id);
      return;
    }

    final ended = endTime ?? DateTime.now();
    final captured = captureBody(
      responseBody,
      contentType: contentType,
      url: current.url,
    );
    _store.update(id, (entry) {
      final hasNewBody = captured.body != null;
      final body = hasNewBody ? captured.body : entry.responseBody;
      final originalSize = hasNewBody
          ? captured.originalSize
          : entry.responseBodyOriginalSize;
      return entry.copyWith(
        statusCode: statusCode,
        responseHeaders: responseHeaders == null
            ? entry.responseHeaders
            : Map<String, String>.unmodifiable(responseHeaders),
        responseBody: body,
        responseBodyOriginalSize: originalSize,
        endTime: ended,
        sizeBytes:
            FerretMessageSize.messageBytes(
              headers: entry.requestHeaders,
              body: entry.requestBody,
              originalBodySize: entry.requestBodyOriginalSize,
            ) +
            FerretMessageSize.messageBytes(
              headers: headers,
              body: body,
              originalBodySize: originalSize,
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

  /// Applies `captureBody` and `maxBodyBytes` to a raw body.
  ///
  /// Image/video bodies are never truncated — [maxBodyBytes] only caps
  /// text/JSON. Media URL calls are dropped from the store entirely.
  FerretCapturedBody captureBody(Object? raw, {String? contentType, Uri? url}) {
    if (!_config.captureBody || raw == null) {
      return (body: null, originalSize: null);
    }
    final body = _normalizeBody(raw);
    final media =
        FerretLinks.isMediaContentType(contentType) ||
        (url != null && FerretLinks.isMediaUrl(url.toString()));
    final limit = media ? null : _config.maxBodyBytes;
    if (limit == null || !_mayExceed(body, limit)) {
      return (body: body, originalSize: null);
    }
    if (body is List<int>) {
      if (body.length <= limit) return (body: body, originalSize: null);
      return (body: body.sublist(0, limit), originalSize: body.length);
    }
    final bytes = utf8.encode(body is String ? body : _encode(body));
    if (bytes.length <= limit) return (body: body, originalSize: null);
    // Back off to a character boundary (skip UTF-8 continuation bytes).
    var end = limit;
    while (end > 0 && (bytes[end] & 0xC0) == 0x80) {
      end--;
    }
    return (
      body: utf8.decode(bytes.sublist(0, end)),
      originalSize: bytes.length,
    );
  }

  /// Cheap pre-check that skips encoding bodies that can't exceed [limit].
  /// A UTF-16 code unit encodes to at most 3 UTF-8 bytes.
  static bool _mayExceed(Object body, int limit) {
    if (body is List<int>) return body.length > limit;
    if (body is String) return body.length * 3 > limit;
    return true;
  }

  static String _encode(Object body) {
    try {
      return jsonEncode(body);
    } on Object {
      return body.toString();
    }
  }

  static Object _normalizeBody(Object body) {
    if (body is String || body is List<int> || body is Map || body is List) {
      return body;
    }
    return body.toString();
  }
}
