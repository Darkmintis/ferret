import 'dart:async';

import 'package:flutter/material.dart';

import '../config/ferret_config.dart';
import '../core/ferret_entry.dart';
import '../core/ferret_store.dart';
import 'ferret_dashboard.dart';

/// Simple floating count button. Tap opens the full inspector (Alice-style).
///
/// Shows only the API call count. Flashes red briefly when a new failed call
/// is captured.
class FerretBubble extends StatefulWidget {
  const FerretBubble({
    super.key,
    required this.store,
    required this.config,
    required this.showReleaseTag,
    required this.onReplay,
    this.onClear,
  });

  final FerretStore store;
  final FerretConfig config;
  final bool showReleaseTag;
  final Future<void> Function(FerretEntry entry) onReplay;
  final VoidCallback? onClear;

  @override
  State<FerretBubble> createState() => _FerretBubbleState();
}

class _FerretBubbleState extends State<FerretBubble> {
  static const _flashDuration = Duration(seconds: 2);
  static const _size = 56.0;

  Offset _offset = const Offset(16, 120);
  int _lastFailed = 0;
  bool _errorFlash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _lastFailed = _failedCount;
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  int get _failedCount =>
      widget.store.entries.where((e) => e.isFailed).length;

  void _onStoreChanged() {
    final failed = _failedCount;
    if (failed > _lastFailed) {
      _flashError();
    }
    _lastFailed = failed;
    if (mounted) setState(() {});
  }

  void _flashError() {
    _flashTimer?.cancel();
    setState(() => _errorFlash = true);
    _flashTimer = Timer(_flashDuration, () {
      if (mounted) setState(() => _errorFlash = false);
    });
  }

  void _openDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FerretDashboard(
          store: widget.store,
          config: widget.config,
          onReplay: widget.onReplay,
          onClear: widget.onClear,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final count = widget.store.length;
    final scheme = Theme.of(context).colorScheme;

    final background = _errorFlash ? scheme.error : scheme.inverseSurface;
    final foreground =
        _errorFlash ? scheme.onError : scheme.onInverseSurface;

    return Positioned(
      left: _offset.dx.clamp(8.0, media.size.width - _size - 8),
      top: _offset.dy.clamp(media.padding.top + 8, media.size.height - _size - 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.showReleaseTag)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB3261E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'FERRET ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() => _offset += details.delta);
            },
            onTap: _openDashboard,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _size,
              height: _size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: count >= 100 ? 14 : 16,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
