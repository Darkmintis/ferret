import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ferret/ferret.dart';
import 'package:ferret_example/app.dart';
import 'package:ferret_example/models/post.dart';
import 'package:ferret_example/services/feed_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('example app loads posts from use-case button', (tester) async {
    Ferret.install(config: const FerretConfig(showNotification: false));

    final repository = FeedRepository(
      dio: Dio()
        ..httpClientAdapter = _FakeAdapter(
          posts: const [
            Post(id: 1, userId: 1, title: 'Hello Ferret', body: 'Feed works.'),
          ],
        ),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    await tester.pumpWidget(FerretExampleApp(repository: repository));
    await tester.pump();

    expect(find.text('Load posts'), findsOneWidget);
    expect(find.text('Trigger error'), findsOneWidget);

    await tester.tap(find.text('Load posts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Hello Ferret'), findsOneWidget);

    repository.dispose();
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.posts});

  final List<Post> posts;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object payload = const <Object>[];
    if (options.uri.path.endsWith('/posts') && options.method == 'GET') {
      payload = [
        for (final post in posts)
          {
            'id': post.id,
            'userId': post.userId,
            'title': post.title,
            'body': post.body,
          },
      ];
    }

    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
