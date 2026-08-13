import 'package:flutter/material.dart';

import '../ferret_body_viewer.dart';
import '../ferret_clipboard.dart';
import '../widgets/ferret_section_card.dart';

/// Body section for request/response detail tabs.
class FerretBodySection extends StatelessWidget {
  const FerretBodySection({super.key, required this.body});

  final Object? body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyText = FerretBodyViewer.formatBody(body);
    final hasBody = body != null && bodyText.trim().isNotEmpty;

    return FerretSectionCard(
      title: 'Body',
      trailing: FerretClipboard.copyIcon(
        tooltip: 'Copy body',
        onPressed: () => FerretClipboard.copy(
          context,
          text: bodyText,
          successMessage: 'Body copied',
          emptyMessage: 'Body is empty',
        ),
      ),
      children: [
        if (!hasBody)
          Text(
            'Body is empty',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          )
        else
          SelectableText.rich(
            FerretBodyViewer.highlightJsonKeys(
              bodyText,
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: scheme.onSurface,
                  ) ??
                  const TextStyle(height: 1.45),
            ),
          ),
      ],
    );
  }
}
