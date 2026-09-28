import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import '../../core/ferret_links.dart';
import '../ferret_body_viewer.dart';
import '../ferret_link_sheet.dart';
import '../widgets/ferret_empty_state.dart';
import '../widgets/ferret_section_card.dart';

/// Every URL in a call (request URL, headers, bodies) in one list, so links
/// can be found without scrolling large JSON.
class FerretLinksTab extends StatelessWidget {
  const FerretLinksTab({super.key, required this.entry});

  final FerretEntry entry;

  /// Unique links grouped by where they were first found.
  static List<(String, List<String>)> collect(FerretEntry entry) {
    final seen = <String>{};
    List<String> fresh(Iterable<String> urls) => [
      for (final url in urls)
        if (seen.add(url)) url,
    ];
    String headerText(Map<String, String>? headers) =>
        (headers ?? const {}).values.join('\n');

    final groups = <(String, List<String>)>[
      ('Request URL', fresh(FerretLinks.find(entry.url.toString()))),
      (
        'Request headers',
        fresh(FerretLinks.find(headerText(entry.requestHeaders))),
      ),
      (
        'Request body',
        fresh(FerretLinks.find(FerretBodyViewer.formatBody(entry.requestBody))),
      ),
      (
        'Response headers',
        fresh(FerretLinks.find(headerText(entry.responseHeaders))),
      ),
      (
        'Response body',
        fresh(
          FerretLinks.find(FerretBodyViewer.formatBody(entry.responseBody)),
        ),
      ),
    ];
    return [
      for (final g in groups)
        if (g.$2.isNotEmpty) g,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groups = collect(entry);
    if (groups.isEmpty) {
      return const FerretEmptyState(
        icon: Icons.link_off_rounded,
        title: 'No links',
        message: 'No http(s) URLs were found in this call.',
      );
    }

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          for (final (title, urls) in groups) ...[
            FerretSectionCard(
              title: '$title (${urls.length})',
              children: [for (final url in urls) _LinkRow(url: url)],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isImage = FerretLinks.isImageUrl(url);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isImage ? Icons.image_outlined : Icons.link_rounded,
        color: scheme.primary,
        semanticLabel: isImage ? 'Image link' : 'Link',
      ),
      title: Text(
        url,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.primary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => FerretLinkSheet.show(context, url),
    );
  }
}
