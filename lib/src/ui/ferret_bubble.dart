import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ferret_store.dart';
import 'ferret_theme.dart';

/// Simple floating count button. Tap opens the full inspector.
///
/// Starts near the vertical center on the right edge. Shows only the API call
/// count. Flashes red briefly when a new failed call is captured.
class FerretBubble extends StatefulWidget {
  const FerretBubble({
    super.key,
    required this.store,
    required this.showReleaseTag,
    required this.onOpen,
  });

  final FerretStore store;
  final bool showReleaseTag;
  final VoidCallback onOpen;

  @override
  State<FerretBubble> createState() => _FerretBubbleState();
}

class _FerretBubbleState extends State<FerretBubble> {
  static const _flashDuration = Duration(seconds: 2);
  static const _size = 52.0;
  static const _radius = 14.0;
  static const _edgePad = 16.0;

  Offset? _offset;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _offset ??= _defaultOffset(MediaQuery.sizeOf(context));
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  Offset _defaultOffset(Size size) {
    return Offset(size.width - _size - _edgePad, (size.height - _size) / 2);
  }

  int get _failedCount => widget.store.entries.where((e) => e.isFailed).length;

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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final count = widget.store.length;
    final offset = _offset ?? _defaultOffset(media.size);

    return Positioned(
      left: offset.dx.clamp(8.0, media.size.width - _size - 8),
      top: offset.dy.clamp(
        media.padding.top + 8,
        media.size.height - _size - media.padding.bottom - 24,
      ),
      child: FerretTheme.wrap(context, (context) {
        final scheme = Theme.of(context).colorScheme;
        final background = _errorFlash ? scheme.error : scheme.inverseSurface;
        final foreground = _errorFlash
            ? scheme.onError
            : scheme.onInverseSurface;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.showReleaseTag)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: const Color(0xFFB3261E),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'FERRET ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: background,
              elevation: 3,
              shadowColor: Colors.black38,
              borderRadius: BorderRadius.circular(_radius),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: _size,
                height: _size,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    setState(() {
                      _offset = offset + details.delta;
                    });
                  },
                  onTap: widget.onOpen,
                  child: ColoredBox(
                    color: background,
                    child: Center(
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
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
