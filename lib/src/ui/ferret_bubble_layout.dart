import 'package:flutter/material.dart';

import 'ferret_bubble_button.dart';

/// Computes default and clamped bubble offsets.
///
/// The bubble keeps [edgeMargin] from every screen edge, measured inside the
/// safe area (status bar, navigation bar, notches) — same rule as Mole and
/// Sway.
abstract final class FerretBubbleLayout {
  static const edgeMargin = 12.0;
  static const dragTapSlop = 8.0;

  /// Top-left bounds the bubble may occupy.
  static Rect bounds(MediaQueryData media) {
    final pad = media.padding;
    const size = FerretBubbleButton.size;
    return Rect.fromLTRB(
      pad.left + edgeMargin,
      pad.top + edgeMargin,
      media.size.width - pad.right - size - edgeMargin,
      media.size.height - pad.bottom - size - edgeMargin,
    );
  }

  /// Right edge, vertically centered in the safe area.
  static Offset defaultOffset(MediaQueryData media) {
    final b = bounds(media);
    return Offset(b.right, (b.top + b.bottom) / 2);
  }

  static Offset clamp(Offset offset, MediaQueryData media) {
    final b = bounds(media);
    return Offset(
      offset.dx.clamp(b.left, b.right),
      offset.dy.clamp(b.top, b.bottom),
    );
  }

  /// Snaps X to the nearer horizontal edge; Y stays (clamped).
  static Offset snapToEdge(Offset offset, MediaQueryData media) {
    final b = bounds(media);
    final snapLeft =
        offset.dx + FerretBubbleButton.size / 2 < media.size.width / 2;
    return clamp(Offset(snapLeft ? b.left : b.right, offset.dy), media);
  }
}
