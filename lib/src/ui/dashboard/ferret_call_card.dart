import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import 'ferret_call_colors.dart';
import 'ferret_call_meta_row.dart';
import 'ferret_call_title_row.dart';

/// Single HTTP call row in the dashboard list.
class FerretCallCard extends StatelessWidget {
  const FerretCallCard({
    super.key,
    required this.entry,
    required this.slowThreshold,
    required this.onOpen,
  });

  final FerretEntry entry;
  final Duration slowThreshold;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failed = entry.isFailed;
    final slow = entry.isSlow(slowThreshold);
    final pending = entry.isPending;
    final accent = failed
        ? scheme.error
        : slow
        ? scheme.tertiary
        : pending
        ? scheme.outline
        : FerretCallColors.methodColor(entry.method, scheme);

    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FerretCallTitleRow(
                        entry: entry,
                        failed: failed,
                        pending: pending,
                      ),
                      if (_hasMeta(entry, slow, failed)) ...[
                        const SizedBox(height: 10),
                        FerretCallMetaRow(
                          entry: entry,
                          slow: slow,
                          failed: failed,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _hasMeta(FerretEntry entry, bool slow, bool failed) {
    return entry.duration != null ||
        entry.sizeBytes != null ||
        slow ||
        (failed && entry.error != null);
  }
}
