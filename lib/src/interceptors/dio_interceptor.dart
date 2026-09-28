import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/http_client_type.dart';
import '../core/ferret_capture_scope.dart';
import '../core/ferret_engine.dart';

/// Dio interceptor that records requests into [FerretEngine].
class FerretDioInterceptor extends Interceptor {
  /// Records into a fixed [engine].
  FerretDioInterceptor(FerretEngine engine) : _resolve = (() => engine);

  /// Resolves the engine per request, so the interceptor can be attached
  /// before `Ferret.install()` and passes traffic through while inactive.
  FerretDioInterceptor.lazy(this._resolve);

  final FerretEngine? Function() _resolve;

  static const _entryIdExtra = 'ferret_entry_id';
  static const _scopeExtra = 'ferret_scope_pushed';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final engine = _resolve();
    if (engine == null || !engine.accepts(HttpClientType.dio)) {
      handler.next(options);
      return;
    }

    final headers = _collectRequestHeaders(options);

    final entry = engine.begin(
      client: HttpClientType.dio,
      method: options.method,
      url: options.uri,
      requestHeaders: headers,
      requestBody: _decodeBody(options.data),
    );
    options.extra[_entryIdExtra] = entry.id;

    // Dio uses dart:io under the hood — suppress the duplicate capture.
    FerretCaptureScope.push();
    options.extra[_scopeExtra] = true;

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _popScope(response.requestOptions);
    final id = response.requestOptions.extra[_entryIdExtra] as String?;
    final engine = _resolve();
    if (id != null && engine != null) {
      final reqHeaders = _collectRequestHeaders(response.requestOptions);
      engine.store.update(
        id,
        (current) => current.copyWith(requestHeaders: reqHeaders),
      );
      final headers = <String, String>{};
      response.headers.map.forEach((key, values) {
        headers[key] = values.join(', ');
      });
      engine.complete(
        id: id,
        statusCode: response.statusCode,
        responseHeaders: headers,
        responseBody: _decodeBody(response.data),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _popScope(err.requestOptions);
    final id = err.requestOptions.extra[_entryIdExtra] as String?;
    final engine = _resolve();
    if (id != null && engine != null) {
      final reqHeaders = _collectRequestHeaders(err.requestOptions);
      engine.store.update(
        id,
        (current) => current.copyWith(requestHeaders: reqHeaders),
      );
      final response = err.response;
      if (response != null) {
        final headers = <String, String>{};
        response.headers.map.forEach((key, values) {
          headers[key] = values.join(', ');
        });
        engine.complete(
          id: id,
          statusCode: response.statusCode,
          responseHeaders: headers,
          responseBody: _decodeBody(response.data),
          error: err.message ?? err.toString(),
        );
      } else {
        engine.fail(id, err.message ?? err);
      }
    }
    handler.next(err);
  }

  static Map<String, String> _collectRequestHeaders(RequestOptions options) {
    final headers = <String, String>{};
    options.headers.forEach((key, value) {
      if (value != null) headers[key] = value.toString();
    });
    final contentType = options.contentType?.toString();
    if (contentType != null && contentType.isNotEmpty) {
      headers.putIfAbsent('content-type', () => contentType);
    }
    return headers;
  }

  static void _popScope(RequestOptions options) {
    if (options.extra.remove(_scopeExtra) == true) {
      FerretCaptureScope.pop();
    }
  }

  static Object? _decodeBody(Object? data) {
    if (data == null) return null;
    if (data is String || data is List || data is Map) return data;
    if (data is List<int>) {
      try {
        return utf8.decode(data);
      } on Object {
        return data;
      }
    }
    if (data is FormData) {
      return {
        'fields': [
          for (final e in data.fields) {'key': e.key, 'value': e.value},
        ],
        'files': [
          for (final e in data.files)
            {'key': e.key, 'filename': e.value.filename},
        ],
      };
    }
    if (data is Stream) return '<stream>';
    return data.toString();
  }
}
