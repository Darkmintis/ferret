import 'package:flutter/material.dart';

import 'ferret_bubble_button.dart';

/// Computes default and clamped bubble offsets.
abstract final class FerretBubbleLayout {
  static const edgePad = 16.0;

  static Offset defaultOffset(Size size) {
    return Offset(
      size.width - FerretBubbleButton.size - edgePad,
      (size.height - FerretBubbleButton.size) / 2,
    );
  }

  static Offset clamp(Offset offset, MediaQueryData media) {
    return Offset(
      offset.dx.clamp(8.0, media.size.width - FerretBubbleButton.size - 8),
      offset.dy.clamp(
        media.padding.top + 8,
        media.size.height - FerretBubbleButton.size - media.padding.bottom - 24,
      ),
    );
  }
}
