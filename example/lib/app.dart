import 'package:ferret/ferret.dart';
import 'package:flutter/material.dart';

import 'screens/feed_screen.dart';
import 'services/feed_repository.dart';
import 'theme/app_theme.dart';

class FerretExampleApp extends StatefulWidget {
  const FerretExampleApp({super.key, this.repository});

  /// Injected in tests; created internally for normal runs.
  final FeedRepository? repository;

  @override
  State<FerretExampleApp> createState() => _FerretExampleAppState();
}

class _FerretExampleAppState extends State<FerretExampleApp> {
  late final FeedRepository _repository =
      widget.repository ?? FeedRepository();
  late final bool _ownsRepository = widget.repository == null;

  @override
  void dispose() {
    if (_ownsRepository) {
      _repository.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ferret Feed',
      debugShowCheckedModeBanner: false,
      navigatorKey: Ferret.navigatorKey,
      builder: Ferret.builder,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: FeedScreen(repository: _repository),
    );
  }
}
