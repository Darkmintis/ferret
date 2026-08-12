import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import '../../core/ferret_message_size.dart';
import 'ferret_meta_pill.dart';

/// Duration, size, and error meta pills under a call card title.
class FerretCallMetaRow extends StatelessWidget {
  const FerretCallMetaRow({
    super.key,
    required this.entry,
    required this.slow,
    required this.failed,
  });

  final FerretEntry entry;
  final bool slow;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (entry.duration != null)
          FerretMetaPill(
            icon: Icons.schedule_rounded,
            label: '${entry.duration!.inMilliseconds} ms',
            emphasis: slow,
            color: slow ? scheme.tertiary : scheme.onSurfaceVariant,
          ),
        if (entry.sizeBytes != null)
          FerretMetaPill(
            icon: Icons.swap_vert_rounded,
            label: FerretMessageSize.formatBytes(entry.sizeBytes!),
            color: scheme.onSurfaceVariant,
          ),
        if (failed && entry.error != null)
          FerretMetaPill(
            icon: Icons.error_outline_rounded,
            label: 'Failed',
            emphasis: true,
            color: scheme.error,
          ),
        if (slow)
          FerretMetaPill(
            icon: Icons.speed_rounded,
            label: 'Slow',
            emphasis: true,
            color: scheme.tertiary,
          ),
      ],
    );
  }
}
