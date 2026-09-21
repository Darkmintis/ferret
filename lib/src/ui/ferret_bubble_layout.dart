import 'package:flutter/material.dart';

import 'ferret_bubble_button.dart';

/// Computes default and clamped bubble offsets.
abstract final class FerretBubbleLayout {
  static const edgePad = 16.0;
  static const edgeMargin = 8.0;
  static const dragTapSlop = 8.0;

  static Offset defaultOffset(Size size) {
    return Offset(
      size.width - FerretBubbleButton.size - edgePad,
      (size.height - FerretBubbleButton.size) / 2,
    );
  }

  static Offset clamp(Offset offset, MediaQueryData media) {
    return Offset(
      offset.dx.clamp(
        edgeMargin,
        media.size.width - FerretBubbleButton.size - edgeMargin,
      ),
      offset.dy.clamp(
        media.padding.top + edgeMargin,
        media.size.height - FerretBubbleButton.size - media.padding.bottom - 24,
      ),
    );
  }

  /// Snaps X to the nearer horizontal edge; Y stays (clamped).
  static Offset snapToEdge(Offset offset, MediaQueryData media) {
    final midX = media.size.width / 2;
    final snapLeft = offset.dx + FerretBubbleButton.size / 2 < midX;
    final x = snapLeft
        ? edgeMargin
        : media.size.width - FerretBubbleButton.size - edgeMargin;
    return clamp(Offset(x, offset.dy), media);
  }
}
