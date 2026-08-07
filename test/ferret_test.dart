import 'package:ferret/ferret.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FerretStore', () {
    test('keeps newest first and trims to maxEntries', () {
      final store = FerretStore(maxEntries: 3);

      store.add(_entry('1'));
      store.add(_entry('2'));
      store.add(_entry('3'));
      store.add(_entry('4'));

      expect(store.length, 3);
      expect(store.entries.map((e) => e.id), ['4', '3', '2']);
    });

    test('update replaces by id', () {
      final store = FerretStore(maxEntries: 10);
      store.add(_entry('a', status: null));
      final ok = store.update(
        'a',
        (e) => e.copyWith(statusCode: 200, endTime: DateTime.now()),
      );
      expect(ok, isTrue);
      expect(store.getById('a')!.statusCode, 200);
      expect(store.getById('a')!.isPending, isFalse);
    });

    test('clear empties the buffer', () {
      final store = FerretStore(maxEntries: 5);
      store
        ..add(_entry('1'))
        ..add(_entry('2'))
        ..clear();
      expect(store.isEmpty, isTrue);
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

    test('release warning cannot be disabled when active in release', () {
      final on = FerretActivation.resolve(
        const FerretConfig(enableInRelease: true),
        isReleaseMode: true,
      );
      expect(on.active, isTrue);
      expect(on.showReleaseWarning, isTrue);
    });
  });

  group('FerretFilter', () {
    test('filters failed and method', () {
      final entries = [
        _entry('ok', status: 200, method: 'GET'),
        _entry('bad', status: 500, method: 'POST'),
      ];
      final filtered = const FerretFilter(failedOnly: true, methods: {'POST'})
          .apply(entries, slowThreshold: const Duration(seconds: 2));
      expect(filtered.map((e) => e.id), ['bad']);
    });
  });

  group('FerretStats', () {
    test('counts failed slow and pending', () {
      final now = DateTime.now();
      final entries = [
        _entry('ok', status: 200).copyWith(
          startTime: now,
          endTime: now.add(const Duration(milliseconds: 100)),
        ),
        _entry('bad', status: 500).copyWith(
          startTime: now,
          endTime: now.add(const Duration(milliseconds: 50)),
        ),
        _entry('slow', status: 200).copyWith(
          startTime: now,
          endTime: now.add(const Duration(seconds: 3)),
        ),
        _entry('pending', status: null),
      ];
      final stats = FerretStats.fromEntries(
        entries,
        slowThreshold: const Duration(seconds: 2),
      );
      expect(stats.total, 4);
      expect(stats.failed, 1);
      expect(stats.slow, 1);
      expect(stats.pending, 1);
      expect(stats.statusLine, contains('4 calls'));
      expect(stats.bubbleLabel, '4');
    });
  });

  group('SessionExporter', () {
    test('builds text and json exports', () {
      const config = FerretConfig();
      final entries = [
        _entry('1', status: 200, method: 'GET'),
      ];
      final text = const SessionExporter().export(
        entries,
        format: FerretExportFormat.text,
        config: config,
      );
      final json = const SessionExporter().export(
        entries,
        format: FerretExportFormat.json,
        config: config,
      );
      expect(text, contains('Ferret session'));
      expect(text, contains('GET'));
      expect(json, contains('"generator": "ferret"'));
      expect(json, contains('"total": 1'));
    });
  });

  group('CurlExporter', () {
    test('builds a curl command', () {
      final curl = const CurlExporter().export(
        FerretEntry(
          id: '1',
          client: HttpClientType.dio,
          method: 'POST',
          url: Uri.parse('https://example.com/api'),
          requestHeaders: const {'Authorization': 'Bearer secret'},
          requestBody: '{"a":1}',
          startTime: DateTime.now(),
        ),
        redact: true,
      );
      expect(curl, contains('curl -X POST'));
      expect(curl, contains('***'));
      expect(curl, isNot(contains('Bearer secret')));
    });
  });

  testWidgets('dashboard renders entries', (tester) async {
    final store = FerretStore(maxEntries: 20)
      ..add(
        _entry('1', status: 200, method: 'GET')
            .copyWith(endTime: DateTime.now()),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: FerretDashboard(
          store: store,
          config: const FerretConfig(),
          onReplay: (_) async {},
        ),
      ),
    );

    expect(find.text('Ferret'), findsOneWidget);
    expect(find.textContaining('/'), findsWidgets);
  });
}

FerretEntry _entry(
  String id, {
  int? status = 200,
  String method = 'GET',
}) {
  return FerretEntry(
    id: id,
    client: HttpClientType.http,
    method: method,
    url: Uri.parse('https://example.com/$id'),
    requestHeaders: const {},
    startTime: DateTime.now(),
    statusCode: status,
  );
}
