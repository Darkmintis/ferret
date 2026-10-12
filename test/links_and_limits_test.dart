import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret/ferret.dart';
import 'package:ferret/src/core/ferret_engine.dart';
import 'package:ferret/src/core/ferret_links.dart';
import 'package:ferret/src/ui/detail/ferret_links_tab.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_entries.dart';

void main() {
  group('FerretLinks', () {
    test('finds urls, unescapes JSON slashes, drops trailing punctuation', () {
      const text =
          r'{"img":"https:\/\/cdn.example.com\/a\/b.png","see":"x"} '
          'Visit https://example.com/docs. Or (https://example.com/p_(1)).';
      expect(FerretLinks.find(text), [
        'https://cdn.example.com/a/b.png',
        'https://example.com/docs',
        'https://example.com/p_(1)',
      ]);
    });

    test('dedupes and ignores host-less matches', () {
      expect(FerretLinks.find('https:// http://a.io http://a.io'), [
        'http://a.io',
      ]);
    });

    test('classifies images and video by extension and content-type', () {
      expect(FerretLinks.isImageUrl('https://r2.dev/x/pic.WEBP?v=2'), isTrue);
      expect(FerretLinks.isImageUrl('https://example.com/api/png'), isFalse);
      expect(FerretLinks.isSvgUrl('https://example.com/logo.svg'), isTrue);
      expect(FerretLinks.isImageContentType('image/png; q=1'), isTrue);
      expect(FerretLinks.isImageContentType('application/json'), isFalse);
      expect(FerretLinks.isVideoUrl('https://cdn.example.com/a.mp4'), isTrue);
      expect(FerretLinks.isMediaUrl('https://cdn.example.com/a.JPG'), isTrue);
      expect(FerretLinks.isVideoContentType('video/mp4'), isTrue);
      expect(FerretLinks.isMediaContentType('image/jpeg'), isTrue);
    });

    test('scan is capped for huge text', () {
      final huge = '${'a' * FerretLinks.maxScanChars} https://late.example.com';
      expect(FerretLinks.find(huge), isEmpty);
    });
  });

  group('maxBodyBytes', () {
    FerretEngine engine({int? maxBodyBytes = 10}) => FerretEngine(
      store: FerretStore(maxEntries: 10),
      config: FerretConfig(maxBodyBytes: maxBodyBytes),
    );

    test('keeps small bodies whole', () {
      final captured = engine().captureBody('short');
      expect(captured.body, 'short');
      expect(captured.originalSize, isNull);
    });

    test('truncates strings, bytes and JSON maps, remembering full size', () {
      final e = engine();
      final text = e.captureBody('0123456789abcdef');
      expect(text.body, '0123456789');
      expect(text.originalSize, 16);

      final bytes = e.captureBody(List<int>.filled(25, 1));
      expect((bytes.body! as List<int>).length, 10);
      expect(bytes.originalSize, 25);

      final map = e.captureBody({'key': 'a long value here'});
      expect(map.body, isA<String>());
      expect(
        map.originalSize,
        utf8.encode('{"key":"a long value here"}').length,
      );
    });

    test('cuts at a character boundary, never mid-character', () {
      // a = 1 byte, é = 2, € = 3: a 4-byte cut would land inside the €.
      final captured = engine(maxBodyBytes: 4).captureBody('aé€€');
      expect(captured.body, 'aé');
      expect(captured.originalSize, 9);
    });

    test('null keeps whole bodies', () {
      final captured = engine(maxBodyBytes: null).captureBody('x' * 5000);
      expect((captured.body! as String).length, 5000);
    });

    test('image and video bodies ignore maxBodyBytes', () {
      final bytes = List<int>.filled(100, 7);
      final image = engine().captureBody(bytes, contentType: 'image/jpeg');
      expect(image.body, bytes);
      expect(image.originalSize, isNull);

      final video = engine().captureBody(bytes, contentType: 'video/mp4');
      expect(video.body, bytes);
      expect(video.originalSize, isNull);
    });

    test('media URL calls stay off the store / home list', () {
      final e = engine();
      final skipped = e.begin(
        client: HttpClientType.http,
        method: 'GET',
        url: Uri.parse('https://cdn.example.com/pic.jpg'),
      );
      e.complete(
        id: skipped.id,
        statusCode: 200,
        responseHeaders: const {'content-type': 'image/jpeg'},
        responseBody: List<int>.filled(20, 1),
      );
      expect(e.store.isEmpty, isTrue);

      final api = e.begin(
        client: HttpClientType.http,
        method: 'GET',
        url: Uri.parse('https://api.example.com/avatar'),
      );
      e.complete(
        id: api.id,
        statusCode: 200,
        responseHeaders: const {'content-type': 'image/png'},
        responseBody: List<int>.filled(20, 2),
      );
      expect(e.store.getById(api.id), isNull);
      expect(e.store.isEmpty, isTrue);
    });

    test('entry size reports the full, untruncated size', () {
      final e = engine();
      final entry = e.begin(
        client: HttpClientType.http,
        method: 'GET',
        url: Uri.parse('https://example.com'),
      );
      e.complete(id: entry.id, statusCode: 200, responseBody: 'x' * 100);
      final done = e.store.getById(entry.id)!;
      expect(done.responseBodyTruncated, isTrue);
      expect(done.responseBodyOriginalSize, 100);
      expect(done.sizeBytes, 100);
    });

    test('streamed request bodies are truncated too', () {
      final e = engine();
      final entry = e.begin(
        client: HttpClientType.dartIo,
        method: 'POST',
        url: Uri.parse('https://example.com'),
      );
      e.setRequestBody(entry.id, 'y' * 50);
      final updated = e.store.getById(entry.id)!;
      expect(updated.requestBody, 'y' * 10);
      expect(updated.requestBodyOriginalSize, 50);
    });
  });

  group('links UI', () {
    const imageUrl = 'https://cdn.example.com/missing.png';
    final entry = completedEntry(
      '1',
      responseHeaders: const {
        'content-type': 'application/json',
        'link': '<https://api.example.com/page/2>; rel="next"',
      },
      responseBody: '{"avatar":"$imageUrl","home":"https://example.com"}',
    );

    Future<void> pumpDetail(
      WidgetTester tester, {
      FerretEntry? of,
      void Function(Uri)? onOpenUrl,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FerretDetailView(
            entry: of ?? entry,
            slowThreshold: const Duration(seconds: 2),
            onOpenUrl: onOpenUrl,
          ),
        ),
      );
    }

    test('Links tab groups unique urls by source', () {
      final groups = FerretLinksTab.collect(entry);
      expect(groups.map((g) => g.$1), [
        'Request URL',
        'Response headers',
        'Response body',
      ]);
      expect(groups.last.$2, [imageUrl, 'https://example.com']);
    });

    testWidgets('body links are tappable and open the link sheet', (
      tester,
    ) async {
      await pumpDetail(tester);
      await tester.tap(find.text('Response'));
      await tester.pumpAndSettle();

      final recognizer = _linkRecognizers(tester, 'https://example.com').first;
      recognizer.onTap!();
      await tester.pumpAndSettle();

      expect(find.text('Link'), findsOneWidget);
      expect(find.byTooltip('Copy link'), findsOneWidget);
      expect(find.byTooltip('Open link'), findsNothing);
      expect(find.byTooltip('Preview image'), findsNothing);
    });

    testWidgets('headers and body collapse and expand', (tester) async {
      await pumpDetail(tester);
      await tester.tap(find.text('Response'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Copy body'), findsOneWidget);
      expect(_linkRecognizers(tester, 'https://example.com'), isNotEmpty);

      await tester.tap(find.byTooltip('Collapse Body'));
      await tester.pumpAndSettle();
      expect(_linkRecognizers(tester, 'https://example.com'), isEmpty);

      await tester.tap(find.byTooltip('Expand Body'));
      await tester.pumpAndSettle();
      expect(_linkRecognizers(tester, 'https://example.com'), isNotEmpty);
      expect(find.byTooltip('Collapse Headers'), findsOneWidget);
    });

    testWidgets('Open calls FerretConfig.onOpenUrl', (tester) async {
      Uri? opened;
      await pumpDetail(tester, onOpenUrl: (uri) => opened = uri);
      await tester.tap(find.text('Links'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('https://example.com'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open link'));
      await tester.pumpAndSettle();
      expect(opened, Uri.parse('https://example.com'));
    });

    testWidgets('video links are not auto-loaded', (tester) async {
      const videoUrl = 'https://cdn.example.com/clip.mp4';
      await pumpDetail(
        tester,
        of: completedEntry(
          'v1',
          responseHeaders: const {'content-type': 'application/json'},
          responseBody: '{"clip":"$videoUrl"}',
        ),
      );
      await tester.tap(find.text('Links'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(videoUrl));
      await tester.pumpAndSettle();

      expect(find.text('Video link'), findsOneWidget);
      expect(find.byTooltip('Preview image'), findsNothing);
      expect(find.textContaining('Videos are not auto-loaded'), findsOneWidget);
    });

    testWidgets('image preview loads on tap and shows the HTTP status', (
      tester,
    ) async {
      await pumpDetail(tester);
      await tester.tap(find.text('Links'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(imageUrl));
      await tester.pumpAndSettle();

      expect(find.text('Image link'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await tester.tap(find.byTooltip('Preview image'));
      await tester.pumpAndSettle();

      // flutter_test answers every network request with HTTP 400.
      expect(find.textContaining('HTTP 400'), findsOneWidget);

      await tester.tap(find.byTooltip('Hide preview'));
      await tester.pumpAndSettle();
      expect(find.textContaining('HTTP 400'), findsNothing);
    });

    testWidgets('truncated bodies show a notice', (tester) async {
      await pumpDetail(
        tester,
        of: testEntry(
          '2',
          responseBody: 'x' * 10,
          responseHeaders: const {'content-type': 'text/plain'},
        ).copyWith(responseBodyOriginalSize: 4096),
      );
      await tester.tap(find.text('Response'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Truncated: showing 10 B of 4.0 KB'),
        findsOne,
      );
    });

    testWidgets('image/* response bodies preview instead of base64', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        of: testEntry(
          '3',
          responseBody: Uint8List.fromList(_onePixelPng),
          responseHeaders: const {'content-type': 'image/png'},
        ),
      );
      await tester.tap(find.text('Response'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('image/png'), findsWidgets);
      expect(find.textContaining(base64Encode(_onePixelPng)), findsNothing);
    });
  });
}

List<TapGestureRecognizer> _linkRecognizers(WidgetTester tester, String url) {
  final found = <TapGestureRecognizer>[];
  for (final widget in tester.widgetList<SelectableText>(
    find.byType(SelectableText),
  )) {
    widget.textSpan?.visitChildren((span) {
      if (span is TextSpan &&
          span.text == url &&
          span.recognizer is TapGestureRecognizer) {
        found.add(span.recognizer! as TapGestureRecognizer);
      }
      return true;
    });
  }
  return found;
}

const _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
