import 'package:flutter/material.dart';

/// Draggable count button content for [FerretBubble].
///
/// Pan-only gestures (no competing [GestureDetector.onTap]) so drag starts
/// immediately — same model as Sway's floating button.
class FerretBubbleButton extends StatelessWidget {
  const FerretBubbleButton({
    super.key,
    required this.count,
    required this.background,
    required this.foreground,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final int count;
  final Color background;
  final Color foreground;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  static const size = 48.0;
  static const radius = 12.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      elevation: 3,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
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
    );
  }
}
