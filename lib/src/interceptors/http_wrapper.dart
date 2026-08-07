import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/http_client_type.dart';
import '../core/ferret_capture_scope.dart';
import '../core/ferret_engine.dart';

/// Wraps a [`package:http`] [http.Client] and records traffic.
class FerretHttpClient extends http.BaseClient {
  FerretHttpClient(this._inner, this._engine);

  final http.Client _inner;
  final FerretEngine _engine;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_engine.accepts(HttpClientType.http)) {
      return _inner.send(request);
    }

    Object? requestBody;
    if (request is http.Request) {
      requestBody = request.body.isEmpty ? null : request.body;
    } else if (request is http.MultipartRequest) {
      requestBody = {
        'fields': request.fields,
        'files': [
          for (final f in request.files)
            {'field': f.field, 'filename': f.filename, 'length': f.length},
        ],
      };
    }

    final entry = _engine.begin(
      client: HttpClientType.http,
      method: request.method,
      url: request.url,
      requestHeaders: Map<String, String>.from(request.headers),
      requestBody: requestBody,
    );

    try {
      // package:http uses dart:io under the hood — suppress the duplicate.
      final response = await FerretCaptureScope.runSuppressed(
        () => _inner.send(request),
      );
      final bytes = await response.stream.toBytes();
      Object? body;
      try {
        body = utf8.decode(bytes);
      } on Object {
        body = bytes;
      }

      _engine.complete(
        id: entry.id,
        statusCode: response.statusCode,
        responseHeaders: response.headers,
        responseBody: body,
      );

      return http.StreamedResponse(
        Stream<List<int>>.value(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } on Object catch (error, stackTrace) {
      _engine.fail(entry.id, error, stackTrace);
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}

/// Reads a [http.ByteStream] into bytes (kept for tests / helpers).
Future<Uint8List> readHttpByteStream(http.ByteStream stream) =>
    stream.toBytes();
