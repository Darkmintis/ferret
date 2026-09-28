import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/ferret_links.dart';

/// Image preview for a URL or captured bytes.
///
/// Network previews make a real request (without the app's auth headers) as
/// soon as they are built, so only build one after an explicit user action.
/// Failures show the HTTP status instead of a blank box. Tap a loaded image
/// for full screen.
class FerretImagePreview extends StatelessWidget {
  /// Preview of a remote image.
  const FerretImagePreview.network(String this.url, {super.key}) : bytes = null;

  /// Preview of captured response bytes (no network request).
  const FerretImagePreview.memory(Uint8List this.bytes, {super.key})
    : url = null;

  final String? url;
  final Uint8List? bytes;

  static const double height = 180;

  ImageProvider get _provider =>
      bytes != null ? MemoryImage(bytes!) : NetworkImage(url!);

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url != null && FerretLinks.isSvgUrl(url)) {
      return const _PreviewMessage(
        icon: Icons.image_not_supported_outlined,
        text: 'SVG previews are not supported. Copy or open the link.',
      );
    }

    return Semantics(
      button: true,
      label: 'Image preview, tap for full screen',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openFullScreen(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: FerretImagePreview.height,
            ),
            child: Image(
              image: _provider,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 64,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, _) => _PreviewMessage(
                icon: Icons.broken_image_outlined,
                text: describeError(error),
                isError: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    final provider = _provider;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              url ?? 'Response image',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          body: InteractiveViewer(
            maxScale: 8,
            child: Center(
              child: Image(
                image: provider,
                errorBuilder: (context, error, _) => _PreviewMessage(
                  icon: Icons.broken_image_outlined,
                  text: describeError(error),
                  isError: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "HTTP 404" for network failures, otherwise a short reason.
  static String describeError(Object error) {
    if (error is NetworkImageLoadException) {
      return 'HTTP ${error.statusCode} — image failed to load';
    }
    final text = '$error';
    return 'Could not load image: '
        '${text.length > 160 ? '${text.substring(0, 160)}…' : text}';
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: isError ? FontWeight.w700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
