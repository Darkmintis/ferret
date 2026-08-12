import 'package:flutter/material.dart';

/// Draggable count button content for [FerretBubble].
class FerretBubbleButton extends StatelessWidget {
  const FerretBubbleButton({
    super.key,
    required this.count,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.onPanUpdate,
  });

  final int count;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final ValueChanged<DragUpdateDetails> onPanUpdate;

  static const size = 52.0;
  static const radius = 14.0;

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
          onPanUpdate: onPanUpdate,
          onTap: onTap,
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
