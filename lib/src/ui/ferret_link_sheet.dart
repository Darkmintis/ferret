import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ferret_links.dart';
import 'ferret_clipboard.dart';
import 'ferret_theme.dart';
import 'ferret_ui_feedback.dart';
import 'widgets/ferret_image_preview.dart';

/// Provides `FerretConfig.onOpenUrl` to links inside a detail view.
class FerretLinkScope extends InheritedWidget {
  const FerretLinkScope({
    super.key,
    required this.onOpenUrl,
    required super.child,
  });

  final FutureOr<void> Function(Uri url)? onOpenUrl;

  static FutureOr<void> Function(Uri url)? onOpenUrlOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FerretLinkScope>()?.onOpenUrl;

  @override
  bool updateShouldNotify(FerretLinkScope oldWidget) =>
      onOpenUrl != oldWidget.onOpenUrl;
}

/// Bottom sheet for a tapped link: Copy, Open (when the app supplies
/// `onOpenUrl`) and Preview for images. Links never open straight away.
abstract final class FerretLinkSheet {
  static Future<void> show(BuildContext context, String url) {
    final onOpenUrl = FerretLinkScope.onOpenUrlOf(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => FerretTheme.wrap(
        context,
        (context) => _LinkSheetBody(url: url, onOpenUrl: onOpenUrl),
      ),
    );
  }
}

class _LinkSheetBody extends StatefulWidget {
  const _LinkSheetBody({required this.url, required this.onOpenUrl});

  final String url;
  final FutureOr<void> Function(Uri url)? onOpenUrl;

  @override
  State<_LinkSheetBody> createState() => _LinkSheetBodyState();
}

class _LinkSheetBodyState extends State<_LinkSheetBody> {
  bool _preview = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = widget.url;
    final isImage = FerretLinks.isImageUrl(url);
    final uri = Uri.tryParse(url);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isImage ? 'Image link' : 'Link',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Copy link',
                  onPressed: () => FerretClipboard.copy(
                    context,
                    text: url,
                    successMessage: 'Link copied',
                  ),
                  icon: const Icon(Icons.copy_rounded),
                ),
                if (isImage)
                  IconButton.filledTonal(
                    tooltip: _preview ? 'Hide preview' : 'Preview image',
                    isSelected: _preview,
                    onPressed: () => setState(() => _preview = !_preview),
                    icon: const Icon(Icons.visibility_outlined),
                    selectedIcon: const Icon(Icons.visibility_off_outlined),
                  ),
                if (widget.onOpenUrl != null && uri != null)
                  IconButton.filledTonal(
                    tooltip: 'Open link',
                    onPressed: () => _open(context, uri),
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(url, style: Theme.of(context).textTheme.bodyMedium),
            if (_preview) ...[
              const SizedBox(height: 16),
              FerretImagePreview.network(url),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) {
    return FerretUiFeedback.run(
      context,
      action: () async => widget.onOpenUrl!(uri),
      successMessage: '',
      failurePrefix: 'Open failed',
    );
  }
}
