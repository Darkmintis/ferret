import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ferret/ferret.dart';
import 'package:ferret/src/core/ferret_capture_scope.dart';
import 'package:ferret/src/core/ferret_engine.dart';
import 'package:ferret/src/interceptors/dio_interceptor.dart';
import 'package:ferret/src/interceptors/http_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  tearDown(FerretCaptureScope.resetForTest);

  group('FerretDioInterceptor', () {
    late FerretStore store;
    late FerretEngine engine;
    late Dio dio;

    setUp(() {
      store = FerretStore(maxEntries: 20);
      engine = FerretEngine(store: store, config: const FerretConfig());
      dio = Dio()
        ..httpClientAdapter = _OkDioAdapter()
        ..interceptors.add(FerretDioInterceptor(engine));
    });

    test('captures successful request and response', () async {
      final response = await dio.get<dynamic>('https://example.com/posts');
      expect(response.statusCode, 200);
      expect(store.length, 1);
      final entry = store.entries.single;
      expect(entry.client, HttpClientType.dio);
      expect(entry.method, 'GET');
      expect(entry.statusCode, 200);
      expect(entry.responseBody, contains('ok'));
      expect(entry.endTime, isNotNull);
      expect(FerretCaptureScope.isSuppressed, isFalse);
    });

    test('captures error responses and pops scope', () async {
      dio.httpClientAdapter = _ErrorDioAdapter(status: 404, body: 'missing');
      await expectLater(
        () => dio.get<dynamic>('https://example.com/missing'),
        throwsA(isA<DioException>()),
      );
      expect(store.length, 1);
      final entry = store.entries.single;
      expect(entry.statusCode, 404);
      expect(entry.error, isNotNull);
      expect(FerretCaptureScope.isSuppressed, isFalse);
    });

    test('captures connection failures', () async {
      dio.httpClientAdapter = _ThrowDioAdapter();
      await expectLater(
        () => dio.get<dynamic>('https://example.com/down'),
        throwsA(isA<DioException>()),
      );
      final entry = store.entries.single;
      expect(entry.isFailed, isTrue);
      expect(entry.error, isNotNull);
      expect(FerretCaptureScope.isSuppressed, isFalse);
    });

    test('skips capture when dio client disabled', () async {
      final limited = FerretEngine(
        store: store,
        config: const FerretConfig(clients: {HttpClientType.http}),
      );
      final local = Dio()
        ..httpClientAdapter = _OkDioAdapter()
        ..interceptors.add(FerretDioInterceptor(limited));
      await local.get<dynamic>('https://example.com');
      expect(store.isEmpty, isTrue);
    });

    test('records FormData shape', () async {
      await dio.post<dynamic>(
        'https://example.com/upload',
        data: FormData.fromMap({
          'name': 'Ada',
          'file': MultipartFile.fromString('x', filename: 'a.txt'),
        }),
      );
      final body = Map<String, dynamic>.from(
        store.entries.single.requestBody! as Map,
      );
      expect(body['fields'], isA<List<dynamic>>());
      expect(body['files'], isA<List<dynamic>>());
    });
  });

  group('FerretHttpClient', () {
    test('captures request and reconstitutes response bytes', () async {
      final store = FerretStore(maxEntries: 10);
      final engine = FerretEngine(
        store: store,
        config: const FerretConfig(),
      );
      final client = FerretHttpClient(_FakeHttpClient(), engine);
      final response = await client.get(Uri.parse('https://example.com/api'));
      expect(response.statusCode, 200);
      expect(response.body, '{"ok":true}');
      expect(store.length, 1);
      expect(store.entries.single.client, HttpClientType.http);
      expect(store.entries.single.responseBody, '{"ok":true}');
      expect(FerretCaptureScope.isSuppressed, isFalse);
    });

    test('records failures and rethrows', () async {
      final store = FerretStore(maxEntries: 10);
      final engine = FerretEngine(
        store: store,
        config: const FerretConfig(),
      );
      final client = FerretHttpClient(_FailingHttpClient(), engine);
      await expectLater(
        () => client.get(Uri.parse('https://example.com')),
        throwsA(isA<http.ClientException>()),
      );
      expect(store.entries.single.isFailed, isTrue);
    });

    test('passthrough when http client disabled', () async {
      final store = FerretStore(maxEntries: 10);
      final engine = FerretEngine(
        store: store,
        config: const FerretConfig(clients: {HttpClientType.dio}),
      );
      final client = FerretHttpClient(_FakeHttpClient(), engine);
      final response = await client.get(Uri.parse('https://example.com'));
      expect(response.statusCode, 200);
      expect(store.isEmpty, isTrue);
    });

    test('readHttpByteStream collects bytes', () async {
      final bytes = await readHttpByteStream(
        http.ByteStream(Stream<List<int>>.value(utf8.encode('abc'))),
      );
      expect(bytes, utf8.encode('abc'));
    });
  });
}

class _OkDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ErrorDioAdapter implements HttpClientAdapter {
  _ErrorDioAdapter({required this.status, required this.body});

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['text/plain'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode('{"ok":true}')),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

class _FailingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw http.ClientException('nope', request.url);
  }
}
