import 'package:flutter/material.dart';

import '../config/ferret_config.dart';
import '../core/ferret_entry.dart';
import '../core/ferret_store.dart';
import 'ferret_dashboard.dart';

/// Floating draggable bubble that opens the Ferret dashboard.
class FerretBubble extends StatefulWidget {
  const FerretBubble({
    super.key,
    required this.store,
    required this.config,
    required this.showReleaseTag,
    required this.onReplay,
    this.onClear,
    this.initiallyMinimized = true,
  });

  final FerretStore store;
  final FerretConfig config;
  final bool showReleaseTag;
  final Future<void> Function(FerretEntry entry) onReplay;
  final VoidCallback? onClear;
  final bool initiallyMinimized;

  @override
  State<FerretBubble> createState() => _FerretBubbleState();
}

class _FerretBubbleState extends State<FerretBubble> {
  late bool _minimized;
  Offset _offset = const Offset(16, 120);

  @override
  void initState() {
    super.initState();
    _minimized = widget.initiallyMinimized;
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
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
    final failed = widget.store.entries.where((e) => e.isFailed).length;

    return Positioned(
      left: _offset.dx.clamp(0, media.size.width - 72),
      top: _offset.dy.clamp(media.padding.top, media.size.height - 120),
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
              setState(() {
                _offset += details.delta;
              });
            },
            onTap: () {
              if (_minimized) {
                setState(() => _minimized = false);
              } else {
                _openDashboard();
              }
            },
            onLongPress: () {
              setState(() => _minimized = !_minimized);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: _minimized ? 52 : 148,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    size: 22,
                  ),
                  if (!_minimized) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        failed > 0 ? '$count · $failed fail' : '$count calls',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
