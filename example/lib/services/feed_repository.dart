import 'package:dio/dio.dart';
import 'package:ferret/ferret.dart';
import 'package:http/http.dart' as http;

import '../models/post.dart';

/// Demo API helpers — each method maps to a Ferret use case.
class FeedRepository {
  FeedRepository({
    Dio? dio,
    http.Client? httpClient,
    this.baseUrl = 'https://jsonplaceholder.typicode.com',
  }) : _dio =
           dio ??
           Ferret.createDio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 12),
               receiveTimeout: const Duration(seconds: 12),
             ),
           ),
       _http = httpClient ?? Ferret.wrapClient(http.Client());

  final String baseUrl;
  final Dio _dio;
  final http.Client _http;

  /// Use case: successful Dio GET with a response body.
  Future<List<Post>> loadPosts({int limit = 5}) async {
    final response = await _dio.get<List<dynamic>>(
      '/posts',
      options: Options(
        headers: const {
          'Accept': 'application/json',
          'Accept-Language': 'en',
          'Authorization': 'Bearer demo-token',
        },
      ),
    );
    final list = response.data ?? const <dynamic>[];
    return list
        .take(limit)
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  /// Use case: Dio POST with a request body.
  Future<void> createPost() async {
    await _dio.post<dynamic>(
      '/posts',
      data: {'title': 'ferret', 'body': 'hello', 'userId': 1},
    );
  }

  /// Use case: package:http client (still captured by Ferret).
  Future<void> httpGet() async {
    await _http.get(Uri.parse('$baseUrl/todos/1'));
  }

  /// Use case: images → body preview, tappable image links, Links tab.
  ///
  /// The GET returns `image/jpeg` bytes (rendered inline). The POST echoes a
  /// JSON body with image URLs: one loads, one 404s (preview shows the HTTP
  /// status), one is SVG (preview unsupported).
  Future<void> loadImages() async {
    await _dio.get<List<int>>(
      'https://picsum.photos/id/237/300/200.jpg',
      options: Options(responseType: ResponseType.bytes),
    );
    await _dio.post<dynamic>(
      '/posts',
      data: {
        'title': 'gallery',
        'cover': 'https://picsum.photos/id/1025/600/400.jpg',
        'thumbnail': 'https://picsum.photos/id/does-not-exist/200.jpg',
        'logo':
            'https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg',
        'docs': 'https://pub.dev/packages/ferret',
      },
    );
  }

  /// Use case: failed call → Error tab in Ferret.
  Future<void> triggerError() async {
    await _dio.get<dynamic>('/this-does-not-exist-404');
  }

  void dispose() {
    _http.close();
    _dio.close();
  }
}
