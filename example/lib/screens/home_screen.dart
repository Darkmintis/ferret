import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/feed_repository.dart';

/// Four buttons = four Ferret use cases (success GET, POST, http, error).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final FeedRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> _posts = const [];
  String _status = 'Tap a button, then open the Ferret bubble';
  bool _busy = false;

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = 'Running $label…';
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _status = '$label done — open Ferret');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _status = '$label failed — open Ferret Error tab\n$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _busy = true;
      _status = 'Loading posts…';
    });
    try {
      final posts = await widget.repository.loadPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _status = 'Loaded ${posts.length} posts — open Ferret';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Load posts failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ferret Demo')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'Each button shows a different Ferret use case. Open the bubble to inspect.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _UseCaseButton(
                  label: 'Load posts',
                  subtitle: 'Dio GET',
                  color: const Color(0xFF1B6B4A),
                  enabled: !_busy,
                  onPressed: _loadPosts,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UseCaseButton(
                  label: 'Create post',
                  subtitle: 'Dio POST',
                  color: const Color(0xFF1565C0),
                  enabled: !_busy,
                  onPressed: () => _run(
                    'Create post',
                    widget.repository.createPost,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _UseCaseButton(
                  label: 'http GET',
                  subtitle: 'package:http',
                  color: const Color(0xFF6A1B9A),
                  enabled: !_busy,
                  onPressed: () => _run(
                    'http GET',
                    widget.repository.httpGet,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UseCaseButton(
                  label: 'Trigger error',
                  subtitle: '404',
                  color: const Color(0xFFC62828),
                  enabled: !_busy,
                  onPressed: () => _run(
                    'Trigger error',
                    widget.repository.triggerError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _status,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Text('Posts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_posts.isEmpty)
            Text(
              'Tap “Load posts” to fill this list.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          else
            for (final post in _posts) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(post.title),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _UseCaseButton extends StatelessWidget {
  const _UseCaseButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
