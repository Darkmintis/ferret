import 'package:ferret/ferret.dart';
import 'package:ferret/src/core/ferret_capture_scope.dart';
import 'package:ferret/src/core/ferret_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_entries.dart';

void main() {
  group('FerretEntry', () {
    test('isFailed for status >= 400 or error', () {
      expect(testEntry('a', status: 399).isFailed, isFalse);
      expect(testEntry('b', status: 400).isFailed, isTrue);
      expect(testEntry('c', status: 200, error: 'boom').isFailed, isTrue);
      expect(testEntry('d', status: null, error: 'x').isFailed, isTrue);
    });

    test('isPending until endTime or error settles via endTime', () {
      expect(testEntry('p', status: null).isPending, isTrue);
      expect(
        testEntry('d', status: 200, endTime: DateTime.now()).isPending,
        isFalse,
      );
    });

    test('isSlow respects threshold boundary', () {
      final entry = completedEntry(
        's',
        duration: const Duration(milliseconds: 2000),
      );
      expect(entry.isSlow(const Duration(milliseconds: 2000)), isFalse);
      expect(entry.isSlow(const Duration(milliseconds: 1999)), isTrue);
    });

    test('copyWith clearError clears error', () {
      final cleared = testEntry('e', error: 'nope').copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('host comes from url', () {
      expect(
        testEntry('h', url: Uri.parse('https://api.darkmintis.dev/v1')).host,
        'api.darkmintis.dev',
      );
    });

    test('duration is null when incomplete', () {
      expect(testEntry('x', status: null).duration, isNull);
      final done = completedEntry('y');
      expect(done.duration, const Duration(milliseconds: 120));
    });
  });

  group('FerretStore', () {
    test('keeps newest first and trims to maxEntries', () {
      final store = FerretStore(maxEntries: 3)
        ..add(testEntry('1'))
        ..add(testEntry('2'))
        ..add(testEntry('3'))
        ..add(testEntry('4'));

      expect(store.length, 3);
      expect(store.entries.map((e) => e.id), ['4', '3', '2']);
    });

    test('update replaces by id and returns false when missing', () {
      final store = FerretStore(maxEntries: 10)..add(testEntry('a', status: null));
      expect(
        store.update(
          'a',
          (e) => e.copyWith(statusCode: 200, endTime: DateTime.now()),
        ),
        isTrue,
      );
      expect(store.getById('a')!.statusCode, 200);
      expect(store.update('missing', (e) => e), isFalse);
    });

    test('remove deletes by id and ignores unknown ids', () {
      final store = FerretStore(maxEntries: 5)
        ..add(testEntry('1'))
        ..add(testEntry('2'));
      store.remove('1');
      expect(store.getById('1'), isNull);
      expect(store.length, 1);
      store.remove('ghost');
      expect(store.length, 1);
    });

    test('setMaxEntries shrinks buffer', () {
      final store = FerretStore(maxEntries: 5)
        ..add(testEntry('1'))
        ..add(testEntry('2'))
        ..add(testEntry('3'));
      store.setMaxEntries(2);
      expect(store.length, 2);
      expect(store.entries.map((e) => e.id), ['3', '2']);
    });

    test('clear is no-op when already empty', () {
      final store = FerretStore(maxEntries: 3);
      var notified = 0;
      store.addListener(() => notified++);
      store.clear();
      expect(notified, 0);
      store.add(testEntry('1'));
      store.clear();
      expect(store.isEmpty, isTrue);
      expect(notified, greaterThan(0));
    });

    test('index operator and dispose', () {
      final store = FerretStore(maxEntries: 3)..add(testEntry('1'));
      expect(store[0]!.id, '1');
      store.dispose();
      expect(store.isEmpty, isTrue);
    });
  });

  group('FerretEngine', () {
    test('begin uppercases method and stores request', () {
      final store = FerretStore(maxEntries: 10);
      final engine = FerretEngine(
        store: store,
        config: const FerretConfig(),
      );
      final entry = engine.begin(
        client: HttpClientType.dio,
        method: 'post',
        url: Uri.parse('https://example.com/api'),
        requestHeaders: const {'X-Test': '1'},
        requestBody: {'a': 1},
      );
      expect(entry.method, 'POST');
      expect(store.length, 1);
      expect(store.getById(entry.id)!.requestBody, {'a': 1});
    });

    test('captureBody false drops bodies', () {
      final store = FerretStore(maxEntries: 10);
      final engine = FerretEngine(
        store: store,
        config: const FerretConfig(captureBody: false),
      );
      final entry = engine.begin(
        client: HttpClientType.http,
        method: 'POST',
        url: Uri.parse('https://example.com'),
        requestBody: 'secret',
      );
      engine.complete(
        id: entry.id,
        statusCode: 200,
        responseBody: 'visible',
      );
      final saved = store.getById(entry.id)!;
      expect(saved.requestBody, isNull);
      expect(saved.responseBody, isNull);
      expect(saved.statusCode, 200);
      expect(saved.endTime, isNotNull);
    });

    test('complete sets sizeBytes and clears previous error', () {
      final store = FerretStore(maxEntries: 10);
      final engine = FerretEngine(
        store: store,
        config: const FerretConfig(),
      );
      final entry = engine.begin(
        client: HttpClientType.http,
        method: 'GET',
        url: Uri.parse('https://example.com'),
      );
      engine.fail(entry.id, 'temporary');
      expect(store.getById(entry.id)!.error, contains('temporary'));

      engine.complete(
        id: entry.id,
        statusCode: 200,
        responseHeaders: const {'content-type': 'text/plain'},
        responseBody: 'ok',
      );
      final saved = store.getById(entry.id)!;
      expect(saved.error, isNull);
      expect(saved.sizeBytes, greaterThan(0));
      expect(saved.responseBody, 'ok');
    });

    test('accepts respects configured clients', () {
      final engine = FerretEngine(
        store: FerretStore(maxEntries: 5),
        config: const FerretConfig(clients: {HttpClientType.dio}),
      );
      expect(engine.accepts(HttpClientType.dio), isTrue);
      expect(engine.accepts(HttpClientType.http), isFalse);
    });

    test('updateConfig shrinks store maxEntries', () {
      final store = FerretStore(maxEntries: 5)
        ..add(testEntry('1'))
        ..add(testEntry('2'))
        ..add(testEntry('3'));
      final engine = FerretEngine(
        store: store,
        config: const FerretConfig(maxEntries: 5),
      );
      engine.updateConfig(const FerretConfig(maxEntries: 1));
      expect(store.maxEntries, 1);
      expect(store.length, 1);
    });

    test('nextId is unique', () {
      final engine = FerretEngine(
        store: FerretStore(maxEntries: 5),
        config: const FerretConfig(),
      );
      final ids = {engine.nextId(), engine.nextId(), engine.nextId()};
      expect(ids.length, 3);
    });
  });

  group('FerretActivation', () {
    test('debug respects enabled flag', () {
      expect(
        FerretActivation.resolve(
          const FerretConfig(enabled: true),
          isReleaseMode: false,
        ).active,
        isTrue,
      );
      expect(
        FerretActivation.resolve(
          const FerretConfig(enabled: false),
          isReleaseMode: false,
        ).active,
        isFalse,
      );
    });

    test('release is off unless enableInRelease', () {
      final off = FerretActivation.resolve(
        const FerretConfig(),
        isReleaseMode: true,
      );
      expect(off.active, isFalse);
      expect(off.showReleaseWarning, isFalse);

      final on = FerretActivation.resolve(
        const FerretConfig(enableInRelease: true),
        isReleaseMode: true,
      );
      expect(on.active, isTrue);
      expect(on.showReleaseWarning, isTrue);
    });
  });

  group('FerretConfig', () {
    test('copyWith updates fields', () {
      final config = const FerretConfig(maxEntries: 100)
          .copyWith(enabled: false);
      expect(config.enabled, isFalse);
      expect(config.maxEntries, 100);
    });

    test('toString includes key fields', () {
      expect(
        const FerretConfig(enabled: false).toString(),
        contains('enabled: false'),
      );
    });
  });

  group('FerretFilter', () {
    test('filters failed and method', () {
      final entries = [
        testEntry('ok', status: 200, method: 'GET'),
        testEntry('bad', status: 500, method: 'POST'),
      ];
      final filtered = const FerretFilter(failedOnly: true, methods: {'POST'})
          .apply(entries, slowThreshold: const Duration(seconds: 2));
      expect(filtered.map((e) => e.id), ['bad']);
    });

    test('filters query, domain, and slowOnly', () {
      final now = DateTime.utc(2026, 1, 1);
      final entries = [
        completedEntry('fast', duration: const Duration(milliseconds: 10)),
        testEntry(
          'slow',
          status: 200,
          url: Uri.parse('https://api.example.com/users'),
          startTime: now,
          endTime: now.add(const Duration(seconds: 5)),
        ),
        testEntry(
          'other',
          status: 200,
          url: Uri.parse('https://cdn.other.com/x'),
        ),
      ];

      expect(
        const FerretFilter(query: 'users')
            .apply(entries, slowThreshold: const Duration(seconds: 2))
            .map((e) => e.id),
        ['slow'],
      );
      expect(
        const FerretFilter(domain: 'api.example')
            .apply(entries, slowThreshold: const Duration(seconds: 2))
            .map((e) => e.id),
        ['slow'],
      );
      expect(
        const FerretFilter(slowOnly: true)
            .apply(entries, slowThreshold: const Duration(seconds: 2))
            .map((e) => e.id),
        ['slow'],
      );
    });

    test('isActive and copyWith clearDomain', () {
      expect(FerretFilter.empty.isActive, isFalse);
      expect(const FerretFilter(failedOnly: true).isActive, isTrue);
      final cleared =
          const FerretFilter(domain: 'x').copyWith(clearDomain: true);
      expect(cleared.domain, isNull);
    });
  });

  group('FerretStats', () {
    test('counts failed slow pending and succeeded', () {
      final now = DateTime.now();
      final entries = [
        testEntry('ok', status: 200).copyWith(
          startTime: now,
          endTime: now.add(const Duration(milliseconds: 100)),
        ),
        testEntry('bad', status: 500).copyWith(
          startTime: now,
          endTime: now.add(const Duration(milliseconds: 50)),
        ),
        testEntry('slow', status: 200).copyWith(
          startTime: now,
          endTime: now.add(const Duration(seconds: 3)),
        ),
        testEntry('pending', status: null),
      ];
      final stats = FerretStats.fromEntries(
        entries,
        slowThreshold: const Duration(seconds: 2),
      );
      expect(stats.total, 4);
      expect(stats.failed, 1);
      expect(stats.slow, 1);
      expect(stats.pending, 1);
      expect(stats.succeeded, 2);
      expect(stats.statusLine, contains('4 calls'));
      expect(stats.bubbleLabel, '4');
    });

    test('empty list and fromStore', () {
      final empty = FerretStats.fromEntries(
        const [],
        slowThreshold: const Duration(seconds: 1),
      );
      expect(empty.total, 0);
      expect(empty.statusLine, '0 calls');

      final store = FerretStore(maxEntries: 5)..add(testEntry('1'));
      final fromStore = FerretStats.fromStore(store.entries, const FerretConfig());
      expect(fromStore.total, 1);
    });
  });

  group('FerretCaptureScope', () {
    tearDown(FerretCaptureScope.resetForTest);

    test('suppresses while nested', () async {
      expect(FerretCaptureScope.isSuppressed, isFalse);
      FerretCaptureScope.push();
      expect(FerretCaptureScope.isSuppressed, isTrue);
      await FerretCaptureScope.runSuppressed(() async {
        expect(FerretCaptureScope.isSuppressed, isTrue);
      });
      expect(FerretCaptureScope.isSuppressed, isTrue);
      FerretCaptureScope.pop();
      expect(FerretCaptureScope.isSuppressed, isFalse);
    });

    test('runSuppressed pops depth even when action throws', () async {
      expect(FerretCaptureScope.isSuppressed, isFalse);
      await expectLater(
        () => FerretCaptureScope.runSuppressed(() async {
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect(FerretCaptureScope.isSuppressed, isFalse);
    });

    test('pop never goes negative', () {
      FerretCaptureScope.pop();
      FerretCaptureScope.pop();
      expect(FerretCaptureScope.isSuppressed, isFalse);
    });
  });
}
