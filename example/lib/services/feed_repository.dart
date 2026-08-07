import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ferret/ferret.dart';
import 'package:http/http.dart' as http;

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

/// Loads feed data and fires extra client demos for Ferret.
class FeedRepository {
  FeedRepository({
    Dio? dio,
    http.Client? httpClient,
    this.baseUrl = 'https://jsonplaceholder.typicode.com',
  })  : _dio = dio ??
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

  Future<List<Post>> fetchPosts({int limit = 20}) async {
    final response = await _dio.get<List<dynamic>>('/posts');
    final list = response.data ?? const <dynamic>[];
    return list
        .take(limit)
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<User> fetchUser(int userId) async {
    final response = await _dio.get<Map<String, dynamic>>('/users/$userId');
    return User.fromJson(response.data!);
  }

  Future<Map<int, User>> fetchUsers() async {
    final response = await _dio.get<List<dynamic>>('/users');
    final list = response.data ?? const <dynamic>[];
    final map = <int, User>{};
    for (final item in list) {
      final user = User.fromJson(Map<String, dynamic>.from(item as Map));
      map[user.id] = user;
    }
    return map;
  }

  Future<Post> fetchPost(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
    return Post.fromJson(response.data!);
  }

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>('/posts/$postId/comments');
    final list = response.data ?? const <dynamic>[];
    return list
        .map((e) => Comment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<Post> createPost({
    required String title,
    required String body,
    int userId = 1,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/posts',
      data: {'title': title, 'body': body, 'userId': userId},
    );
    return Post.fromJson(response.data!);
  }

  /// package:http sample — still captured by Ferret.
  Future<Map<String, dynamic>> fetchTodoSample() async {
    final response = await _http.get(Uri.parse('$baseUrl/todos/1'));
    return Map<String, dynamic>.from(
      jsonDecode(response.body) as Map,
    );
  }

  /// dart:io sample — still captured by Ferret.
  Future<void> fetchUserViaDartIo({int userId = 1}) async {
    final client = HttpClient();
    try {
      final request =
          await client.getUrl(Uri.parse('$baseUrl/users/$userId'));
      final response = await request.close();
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  }

  Future<void> triggerNotFound() async {
    await _dio.get<dynamic>('/this-does-not-exist-404');
  }

  void dispose() {
    _http.close();
    _dio.close();
  }
}
