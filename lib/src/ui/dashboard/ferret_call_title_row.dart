import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import 'ferret_method_badge.dart';
import 'ferret_status_badge.dart';

/// Title row for a call card: method badge, path, host, status.
class FerretCallTitleRow extends StatelessWidget {
  const FerretCallTitleRow({
    super.key,
    required this.entry,
    required this.failed,
    required this.pending,
  });

  final FerretEntry entry;
  final bool failed;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = entry.url.path.isEmpty ? '/' : entry.url.path;
    final query = entry.url.hasQuery ? '?${entry.url.query}' : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FerretMethodBadge(method: entry.method),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$path$query',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FerretStatusBadge(entry: entry, failed: failed, pending: pending),
      ],
    );
  }
}
