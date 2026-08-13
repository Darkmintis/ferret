import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import 'ferret_call_colors.dart';

class FerretStatusBadge extends StatelessWidget {
  const FerretStatusBadge({
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

    if (pending) {
      return FerretStatusPill(
        label: '…',
        color: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHighest,
      );
    }

    final code = entry.statusCode;
    if (code == null) return const SizedBox.shrink();

    final color = failed
        ? scheme.error
        : FerretCallColors.statusColor(code, scheme);
    return FerretStatusPill(
      label: '$code',
      color: color,
      background: color.withValues(alpha: 0.12),
      bold: true,
    );
  }
}

class FerretStatusPill extends StatelessWidget {
  const FerretStatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.bold = false,
  });

  final String label;
  final Color color;
  final Color background;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
