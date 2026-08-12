import 'package:flutter/material.dart';

import '../core/ferret_store.dart';
import 'ferret_bubble_button.dart';
import 'ferret_bubble_flash.dart';
import 'ferret_bubble_layout.dart';
import 'ferret_release_tag.dart';
import 'ferret_theme.dart';

/// Simple floating count button. Tap opens the full inspector.
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
  late final FerretBubbleFlash _flash;
  Offset? _offset;

  @override
  void initState() {
    super.initState();
    _flash = FerretBubbleFlash(widget.store);
    widget.store.addListener(_onStore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _offset ??= FerretBubbleLayout.defaultOffset(MediaQuery.sizeOf(context));
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
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
              onTap: widget.onOpen,
              onPanUpdate: (details) {
                setState(() => _offset = offset + details.delta);
              },
            ),
          ],
        );
      }),
    );
  }
}
