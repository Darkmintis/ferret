import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/ferret_links.dart';
import '../../core/ferret_message_size.dart';
import '../ferret_body_viewer.dart';
import '../ferret_clipboard.dart';
import '../widgets/ferret_image_preview.dart';
import '../widgets/ferret_link_text.dart';
import '../widgets/ferret_section_card.dart';

/// Body section for request/response detail tabs.
class FerretBodySection extends StatelessWidget {
  const FerretBodySection({
    super.key,
    required this.body,
    this.originalSize,
    this.contentType,
  });

  final Object? body;

  /// Full body size when [body] was truncated by `maxBodyBytes`.
  final int? originalSize;

  /// Message `content-type`, used to preview `image/*` bodies.
  final String? contentType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = this.body;
    final imageBytes =
        FerretLinks.isImageContentType(contentType) && body is List<int>
        ? body
        : null;
    final videoBytes =
        FerretLinks.isVideoContentType(contentType) && body is List<int>
        ? body
        : null;
    final bodyText = imageBytes == null && videoBytes == null
        ? FerretBodyViewer.formatBody(body)
        : '';
    final hasBody =
        imageBytes != null || videoBytes != null || bodyText.trim().isNotEmpty;

    return FerretSectionCard(
      title: 'Body',
      collapsible: true,
      trailing: imageBytes != null || videoBytes != null
          ? null
          : FerretClipboard.copyIcon(
              tooltip: 'Copy body',
              onPressed: () => FerretClipboard.copy(
                context,
                text: bodyText,
                successMessage: 'Body copied',
                emptyMessage: 'Body is empty',
              ),
            ),
      children: [
        if (originalSize != null) ...[
          _TruncatedNotice(
            shown: body is List<int>
                ? body.length
                : FerretMessageSize.bodyBytes(body),
            total: originalSize!,
          ),
          const SizedBox(height: 10),
        ],
        if (!hasBody)
          Text(
            'Body is empty',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else if (imageBytes != null)
          _imageBody(context, imageBytes)
        else if (videoBytes != null)
          _VideoBodyNotice(
            contentType: contentType,
            bytes: videoBytes,
            originalSize: originalSize,
          )
        else
          FerretLinkText(
            bodyText,
            highlightJsonKeys: true,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurface,
                ) ??
                const TextStyle(height: 1.45),
          ),
      ],
    );
  }

  Widget _imageBody(BuildContext context, List<int> bytes) {
    final label =
        '${contentType?.split(';').first.trim() ?? 'image'}, '
        '${FerretMessageSize.formatBytes(originalSize ?? bytes.length)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        FerretImagePreview.memory(
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        ),
      ],
    );
  }
}

/// Video bodies are never auto-played (no player dependency; heavy files).
class _VideoBodyNotice extends StatelessWidget {
  const _VideoBodyNotice({
    required this.contentType,
    required this.bytes,
    this.originalSize,
  });

  final String? contentType;
  final List<int> bytes;
  final int? originalSize;

  @override
  Widget build(BuildContext context) {
    final size = FerretMessageSize.formatBytes(originalSize ?? bytes.length);
    final type = contentType?.split(';').first.trim() ?? 'video';
    final heavy = (originalSize ?? bytes.length) >= FerretLinks.heavyMediaBytes;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.videocam_outlined, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                heavy
                    ? '$type · $size — not auto-loaded (heavy). '
                          'Copy or open the URL from the Links tab.'
                    : '$type · $size — not auto-played. '
                          'Copy or open the URL from the Links tab.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TruncatedNotice extends StatelessWidget {
  const _TruncatedNotice({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.content_cut_rounded,
              size: 16,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Truncated: showing ${FerretMessageSize.formatBytes(shown)} '
                'of ${FerretMessageSize.formatBytes(total)} '
                '(FerretConfig.maxBodyBytes)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
