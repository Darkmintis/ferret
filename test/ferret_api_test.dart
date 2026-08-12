import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ferret/ferret.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/test_entries.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Ferret.resetForTest);

  group('Ferret facade', () {
    test('install inactive when disabled', () {
      Ferret.install(config: const FerretConfig(enabled: false));
      expect(Ferret.isInstalled, isTrue);
      expect(Ferret.isActive, isFalse);
      expect(Ferret.store, isNull);
      expect(Ferret.dioInterceptor, isA<Interceptor>());
    });

    test('install active captures via createDio', () async {
      Ferret.install(
        config: const FerretConfig(
          clients: {HttpClientType.dio},
        ),
      );
      expect(Ferret.isActive, isTrue);
      expect(Ferret.store, isNotNull);

      final dio = Ferret.createDio()..httpClientAdapter = _OkAdapter();
      await dio.get<dynamic>('https://example.com/items');
      expect(Ferret.store!.length, 1);
      expect(Ferret.store!.entries.single.method, 'GET');
    });

    test('wrapClient records package:http traffic', () async {
      Ferret.install(
        config: const FerretConfig(
          clients: {HttpClientType.http},
        ),
      );
      final client = Ferret.wrapClient(_FakeHttpClient());
      final response = await client.get(Uri.parse('https://example.com'));
      expect(response.statusCode, 200);
      expect(Ferret.store!.length, 1);
      expect(Ferret.store!.entries.single.client, HttpClientType.http);
    });

    test('wrapClient is passthrough when inactive', () {
      Ferret.install(config: const FerretConfig(enabled: false));
      final inner = _FakeHttpClient();
      expect(identical(Ferret.wrapClient(inner), inner), isTrue);
    });

    test('export helpers toCurl and toHar', () {
      Ferret.install();
      final entry = completedEntry(
        '1',
        requestHeaders: const {'Authorization': 'Bearer x'},
        responseBody: '{"ok":true}',
        responseHeaders: const {'content-type': 'application/json'},
      );
      Ferret.store!.add(entry);

      expect(Ferret.toCurl(entry, redact: true), contains('***'));
      expect(Ferret.toHar(), contains('"version": "1.2"'));
    });

    test('clear empties store', () {
      Ferret.install();
      Ferret.store!.add(testEntry('1'));
      Ferret.clear();
      expect(Ferret.store!.isEmpty, isTrue);
    });

    testWidgets('builder stacks bubble host when active', (tester) async {
      Ferret.install();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: Ferret.navigatorKey,
          builder: Ferret.builder,
          home: const Scaffold(body: Text('home')),
        ),
      );
      expect(find.text('home'), findsOneWidget);
    });
  });
}

class _OkAdapter implements HttpClientAdapter {
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

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode('ok')),
      200,
    );
  }
}
