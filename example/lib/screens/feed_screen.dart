import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user.dart';
import '../services/feed_repository.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.repository});

  final FeedRepository repository;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<_FeedData> _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = _load();
  }

  Future<_FeedData> _load() async {
    final results = await Future.wait([
      widget.repository.fetchPosts(),
      widget.repository.fetchUsers(),
    ]);
    return _FeedData(
      posts: results[0] as List<Post>,
      users: results[1] as Map<int, User>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _feedFuture = _load());
    await _feedFuture;
  }

  Future<void> _composePost() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.createPost(
        title: 'Hello from Ferret',
        body: 'Posted from the example social feed.',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Post created — check Ferret')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Post failed: $error')),
      );
    }
  }

  Future<void> _runDemo(Future<void> Function() action, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$label done — open Ferret')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$label failed: $error')),
      );
    }
  }

  void _openPost(Post post, User? user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(
          post: post,
          user: user,
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferret Feed'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Demo other clients',
            onSelected: (value) {
              switch (value) {
                case 'http':
                  _runDemo(
                    () async {
                      await widget.repository.fetchTodoSample();
                    },
                    'http GET',
                  );
                case 'io':
                  _runDemo(
                    () => widget.repository.fetchUserViaDartIo(),
                    'dart:io GET',
                  );
                case '404':
                  _runDemo(
                    () => widget.repository.triggerNotFound(),
                    '404',
                  );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'http',
                child: Text('http · GET /todos/1'),
              ),
              PopupMenuItem(
                value: 'io',
                child: Text('dart:io · GET /users/1'),
              ),
              PopupMenuItem(
                value: '404',
                child: Text('Trigger 404'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _composePost,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Post'),
      ),
      body: FutureBuilder<_FeedData>(
        future: _feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: '${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: EdgeInsets.only(
                bottom: 88 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: data.posts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final post = data.posts[index];
                final user = data.users[post.userId];
                return PostCard(
                  post: post,
                  user: user,
                  onTap: () => _openPost(post, user),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FeedData {
  const _FeedData({required this.posts, required this.users});

  final List<Post> posts;
  final Map<int, User> users;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load feed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
