import 'package:flutter/material.dart';

import '../ferret_body_viewer.dart';
import '../ferret_clipboard.dart';
import '../ferret_header_display.dart';
import '../widgets/ferret_section_card.dart';

/// Headers section for request/response detail tabs.
class FerretHeadersSection extends StatelessWidget {
  const FerretHeadersSection({super.key, required this.headers});

  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sortedHeaders = FerretHeaderDisplay.sorted(headers);
    final copyText = FerretHeaderDisplay.formatForCopy(headers);

    return FerretSectionCard(
      title: 'Headers',
      trailing: FerretClipboard.copyIcon(
        tooltip: 'Copy headers',
        onPressed: () => FerretClipboard.copy(
          context,
          text: copyText,
          successMessage: 'Headers copied',
          emptyMessage: 'No headers to copy',
        ),
      ),
      children: [
        if (sortedHeaders.isEmpty)
          Text(
            'No headers captured',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          )
        else
          for (final header in sortedHeaders)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: FerretHeaderLine(
                name: header.key,
                value: header.value,
                emphasize: FerretHeaderDisplay.isImportant(header.key),
              ),
            ),
      ],
    );
  }
}
