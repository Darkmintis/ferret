import 'dart:convert';

import 'package:ferret/ferret.dart';
import 'package:ferret/src/ui/ferret_body_viewer.dart';
import 'package:ferret/src/ui/ferret_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_entries.dart';

void main() {
  group('FerretBodyViewer', () {
    test('pretty-prints json strings and maps', () {
      final pretty = FerretBodyViewer.formatBody('{"a":1}');
      expect(pretty, contains('\n'));
      expect(pretty, contains('"a"'));
      expect(FerretBodyViewer.formatBody(null), '');
      expect(FerretBodyViewer.formatBody({'b': 2}), contains('"b"'));
    });

    test('decodes utf8 bytes and leaves plain text', () {
      expect(FerretBodyViewer.formatBody('hello'), 'hello');
      expect(FerretBodyViewer.formatBody(utf8Bytes('café')), 'café');
    });

    test('highlightJsonKeys bolds keys', () {
      final span = FerretBodyViewer.highlightJsonKeys(
        '{\n  "userId": 1\n}',
        const TextStyle(),
      );
      expect(span.children, isNotNull);
      expect(span.children!.length, greaterThan(1));
      final bold = span.children!.whereType<TextSpan>().where(
        (s) => s.style?.fontWeight == FontWeight.w700,
      );
      expect(bold, isNotEmpty);
      expect(bold.first.toPlainText(), contains('"userId"'));
    });
  });

  group('FerretHeaderLine', () {
    testWidgets('renders name and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FerretHeaderLine(
              name: 'content-type',
              value: 'application/json',
            ),
          ),
        ),
      );
      expect(find.textContaining('content-type:'), findsOneWidget);
      expect(find.textContaining('application/json'), findsOneWidget);
    });
  });

  group('FerretDashboard', () {
    testWidgets('renders entries and empty state', (tester) async {
      final store = FerretStore(maxEntries: 20)
        ..add(completedEntry('1', method: 'GET'));

      await tester.pumpWidget(
        MaterialApp(
          home: FerretDashboard(store: store, config: const FerretConfig()),
        ),
      );
      expect(find.text('Ferret'), findsOneWidget);
      expect(find.textContaining('/'), findsWidgets);

      store.clear();
      await tester.pump();
      expect(
        find.text('No HTTP calls yet.\nFire a request to see it here.'),
        findsOneWidget,
      );
    });

    testWidgets('export with empty store shows nothing to export', (
      tester,
    ) async {
      final store = FerretStore(maxEntries: 5);
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDashboard(store: store, config: const FerretConfig()),
        ),
      );
      await tester.tap(find.byTooltip('Share HAR'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing to export'), findsOneWidget);
    });

    testWidgets('filtered empty state when no calls match', (tester) async {
      final store = FerretStore(maxEntries: 20)
        ..add(completedEntry('1', method: 'GET', status: 200))
        ..add(completedEntry('2', method: 'POST', status: 500));

      await tester.pumpWidget(
        MaterialApp(
          home: FerretDashboard(store: store, config: const FerretConfig()),
        ),
      );
      await tester.tap(find.byTooltip('Search & filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No calls match your filters.\nTry adjusting search or chips.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('opens detail on list tap', (tester) async {
      final store = FerretStore(maxEntries: 20)
        ..add(completedEntry('1', method: 'GET'));
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDashboard(store: store, config: const FerretConfig()),
        ),
      );
      await tester.tap(find.text('/1'));
      await tester.pumpAndSettle();
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Request'), findsOneWidget);
      expect(find.text('Response'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });
  });

  group('FerretDetailView', () {
    testWidgets('shows request metadata and empty body for GET', (
      tester,
    ) async {
      final entry = completedEntry('1', method: 'GET', status: 201);
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDetailView(
            entry: entry,
            slowThreshold: const Duration(seconds: 2),
          ),
        ),
      );
      expect(find.textContaining('https://example.com/1'), findsOneWidget);
      await tester.tap(find.text('Request'));
      await tester.pumpAndSettle();
      expect(find.text('Bytes sent'), findsOneWidget);
      expect(find.text('Body is empty'), findsOneWidget);
      expect(find.text('No headers captured'), findsOneWidget);
    });

    testWidgets('shows request headers when present', (tester) async {
      final entry = completedEntry(
        '1',
        method: 'GET',
        requestHeaders: const {
          'accept': 'application/json',
          'authorization': 'Bearer demo-token',
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDetailView(
            entry: entry,
            slowThreshold: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.tap(find.text('Request'));
      await tester.pumpAndSettle();
      expect(find.textContaining('accept:'), findsOneWidget);
      expect(find.textContaining('authorization:'), findsOneWidget);
      expect(find.text('Body is empty'), findsOneWidget);
    });

    testWidgets('shows response headers and body', (tester) async {
      final entry = completedEntry(
        '1',
        responseHeaders: const {'content-type': 'application/json'},
        responseBody: '{"ok":true}',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDetailView(
            entry: entry,
            slowThreshold: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.tap(find.text('Response'));
      await tester.pumpAndSettle();
      expect(find.text('Headers'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.textContaining('content-type:'), findsOneWidget);
    });

    testWidgets('copy cURL and share HAR actions are available', (
      tester,
    ) async {
      final entry = completedEntry('1', method: 'POST');
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDetailView(
            entry: entry,
            slowThreshold: const Duration(seconds: 2),
          ),
        ),
      );
      expect(find.byTooltip('Copy as cURL'), findsOneWidget);
      expect(find.byTooltip('Share HAR'), findsOneWidget);
      expect(const CurlExporter().export(entry), contains('curl -X POST'));
    });

    testWidgets('copy headers and body actions are available on request tab', (
      tester,
    ) async {
      final entry = completedEntry(
        '1',
        method: 'POST',
        requestHeaders: const {'content-type': 'application/json'},
        requestBody: '{"name":"ferret"}',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDetailView(
            entry: entry,
            slowThreshold: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.tap(find.text('Request'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Copy headers'), findsOneWidget);
      expect(find.byTooltip('Copy body'), findsOneWidget);
    });

    testWidgets('empty error tab message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDetailView(
            entry: completedEntry('1'),
            slowThreshold: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.tap(find.text('Error'));
      await tester.pumpAndSettle();
      expect(find.text('No error'), findsOneWidget);
    });
  });

  group('FerretBubble', () {
    testWidgets('shows call count', (tester) async {
      final store = FerretStore(maxEntries: 10)
        ..add(completedEntry('1'))
        ..add(completedEntry('2'));
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FerretBubble(
                  store: store,
                  showReleaseTag: false,
                  onOpen: () => opened = true,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('2'));
      expect(opened, isTrue);
    });
  });
}

List<int> utf8Bytes(String value) => utf8.encode(value);
