import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/http_client_type.dart';
import '../core/ferret_engine.dart';

/// Dio interceptor that records requests into [FerretEngine].
class FerretDioInterceptor extends Interceptor {
  FerretDioInterceptor(this._engine);

  final FerretEngine _engine;

  static const _entryIdExtra = 'ferret_entry_id';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_engine.accepts(HttpClientType.dio)) {
      handler.next(options);
      return;
    }

    final headers = <String, String>{};
    options.headers.forEach((key, value) {
      if (value != null) headers[key] = value.toString();
    });

    final entry = _engine.begin(
      client: HttpClientType.dio,
      method: options.method,
      url: options.uri,
      requestHeaders: headers,
      requestBody: _decodeBody(options.data),
    );
    options.extra[_entryIdExtra] = entry.id;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra[_entryIdExtra] as String?;
    if (id != null) {
      final headers = <String, String>{};
      response.headers.map.forEach((key, values) {
        headers[key] = values.join(', ');
      });
      _engine.complete(
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
    final id = err.requestOptions.extra[_entryIdExtra] as String?;
    if (id != null) {
      final response = err.response;
      if (response != null) {
        final headers = <String, String>{};
        response.headers.map.forEach((key, values) {
          headers[key] = values.join(', ');
        });
        _engine.complete(
          id: id,
          statusCode: response.statusCode,
          responseHeaders: headers,
          responseBody: _decodeBody(response.data),
          error: err.message ?? err.toString(),
        );
      } else {
        _engine.fail(id, err.message ?? err);
      }
    }
    handler.next(err);
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
