import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ferret_store.dart';
import 'ferret_bubble_button.dart';
import 'ferret_bubble_flash.dart';
import 'ferret_bubble_layout.dart';
import 'ferret_release_tag.dart';
import 'ferret_theme.dart';

/// ponytail: process-local only (survives inspector open/close + hot reload).
/// Upgrade: shared_preferences if QA needs cross-process restore.
Offset? _persistedBubblePosition;

/// ponytail: process-local hide (survives hot reload until [reassemble] / restart).
bool _userHidden = false;

const _kLongPressHide = Duration(milliseconds: 450);

/// Simple floating count button. Tap opens the full inspector.
/// Long-press hides until hot reload / hot restart (same as Sway).
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

  /// Clears remembered bubble position (tests / [Ferret.resetForTest]).
  static void clearPersistedPositionForTest() {
    _persistedBubblePosition = null;
  }

  /// Clears long-press hide (tests / [Ferret.resetForTest]).
  static void clearUserHiddenForTest() {
    _userHidden = false;
  }

  @override
  State<FerretBubble> createState() => _FerretBubbleState();
}

class _FerretBubbleState extends State<FerretBubble> {
  late final FerretBubbleFlash _flash;
  Offset? _offset;
  double _dragDistance = 0;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _flash = FerretBubbleFlash(widget.store);
    widget.store.addListener(_onStore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _offset ??=
        _persistedBubblePosition ??
        FerretBubbleLayout.defaultOffset(MediaQuery.sizeOf(context));
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_userHidden) {
      _userHidden = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    widget.store.removeListener(_onStore);
    _flash.dispose();
    super.dispose();
  }

  void _onStore() {
    _flash.onStoreChanged(() {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});
  }

  void _persistPosition() {
    if (_offset != null) {
      _persistedBubblePosition = _offset;
    }
  }

  void _hideBubble() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _userHidden = true;
    if (mounted) setState(() {});
  }

  void _onPanStart(DragStartDetails details) {
    _dragDistance = 0;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_kLongPressHide, () {
      if (_dragDistance < FerretBubbleLayout.dragTapSlop &&
          mounted &&
          !_userHidden) {
        _hideBubble();
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final media = MediaQuery.of(context);
    final current = _offset ?? FerretBubbleLayout.defaultOffset(media.size);
    _dragDistance += details.delta.distance;
    if (_dragDistance >= FerretBubbleLayout.dragTapSlop) {
      _longPressTimer?.cancel();
      _longPressTimer = null;
    }
    setState(() => _offset = current + details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    if (!mounted || _userHidden) return;
    if (_dragDistance < FerretBubbleLayout.dragTapSlop) {
      widget.onOpen();
      return;
    }
    final media = MediaQuery.of(context);
    final current = _offset ?? FerretBubbleLayout.defaultOffset(media.size);
    setState(() {
      _offset = FerretBubbleLayout.snapToEdge(current, media);
      _persistPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userHidden) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final offset = FerretBubbleLayout.clamp(
      _offset ?? FerretBubbleLayout.defaultOffset(media.size),
      media,
    );

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: FerretTheme.wrap(context, (context) {
        final scheme = Theme.of(context).colorScheme;
        final flash = _flash.errorFlash;
        final background = flash ? scheme.error : scheme.inverseSurface;
        final foreground = flash ? scheme.onError : scheme.onInverseSurface;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.showReleaseTag)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: FerretReleaseTag(),
              ),
            FerretBubbleButton(
              count: widget.store.length,
              background: background,
              foreground: foreground,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
            ),
          ],
        );
      }),
    );
  }
}
