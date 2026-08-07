import 'package:flutter/material.dart';

import '../config/ferret_config.dart';
import '../core/ferret_entry.dart';
import '../core/ferret_stats.dart';
import '../core/ferret_store.dart';
import 'ferret_dashboard.dart';

/// Floating bubble: shows API call count; tap opens the full inspector.
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
  late bool _compact;
  Offset _offset = const Offset(16, 120);

  @override
  void initState() {
    super.initState();
    _compact = widget.initiallyMinimized;
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
    final stats = FerretStats.fromStore(widget.store.entries, widget.config);
    final scheme = Theme.of(context).colorScheme;
    final countLabel = stats.bubbleLabel;

    return Positioned(
      left: _offset.dx.clamp(0, media.size.width - (_compact ? 64 : 128)),
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
              setState(() => _offset += details.delta);
            },
            onTap: _openDashboard,
            onLongPress: () => setState(() => _compact = !_compact),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 52,
              padding: EdgeInsets.symmetric(horizontal: _compact ? 10 : 14),
              decoration: BoxDecoration(
                color: scheme.inverseSurface,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    color: scheme.onInverseSurface,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _compact ? countLabel : '$countLabel calls',
                    style: TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (stats.failed > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${stats.failed}',
                        style: TextStyle(
                          color: scheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
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
