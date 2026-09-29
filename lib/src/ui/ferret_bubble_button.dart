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
    this.releaseBorder = false,
  });

  final int count;
  final Color background;
  final Color foreground;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  /// Red border marking Ferret as active in a release build.
  final bool releaseBorder;

  static const size = 48.0;
  static const radius = 12.0;
  static const releaseColor = Color(0xFFB3261E);

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background,
      elevation: 3,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: releaseBorder
            ? const BorderSide(color: releaseColor, width: 3)
            : BorderSide.none,
      ),
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
    if (!releaseBorder) return button;
    return Semantics(label: 'Ferret active in release build', child: button);
  }
}
