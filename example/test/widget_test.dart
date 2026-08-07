import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ferret/ferret.dart';
import 'package:ferret_example/app.dart';
import 'package:ferret_example/models/post.dart';
import 'package:ferret_example/models/user.dart';
import 'package:ferret_example/services/feed_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('example app builds a feed', (tester) async {
    Ferret.install(config: const FerretConfig(showNotification: false));

    final repository = FeedRepository(
      dio: Dio()
        ..httpClientAdapter = _FakeAdapter(
          posts: const [
            Post(id: 1, userId: 1, title: 'Hello Ferret', body: 'Feed works.'),
          ],
          users: const [
            User(id: 1, name: 'Jane Doe', username: 'jane'),
          ],
        ),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    await tester.pumpWidget(FerretExampleApp(repository: repository));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ferret Feed'), findsOneWidget);
    expect(find.text('Hello Ferret'), findsOneWidget);

    repository.dispose();
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.posts, required this.users});

  final List<Post> posts;
  final List<User> users;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    Object payload = const <Object>[];
    if (path.endsWith('/posts') && options.method == 'GET') {
      payload = [
        for (final post in posts)
          {
            'id': post.id,
            'userId': post.userId,
            'title': post.title,
            'body': post.body,
          },
      ];
    } else if (path.endsWith('/users') && options.method == 'GET') {
      payload = [
        for (final user in users)
          {
            'id': user.id,
            'name': user.name,
            'username': user.username,
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
