import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import 'ferret_overview_extra_cards.dart';
import 'ferret_overview_general_card.dart';

/// Overview tab for a captured HTTP call.
class FerretOverviewTab extends StatelessWidget {
  const FerretOverviewTab({
    super.key,
    required this.entry,
    required this.duration,
    required this.slow,
  });

  final FerretEntry entry;
  final Duration? duration;
  final bool slow;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        SelectableText(
          entry.url.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        FerretOverviewGeneralCard(
          entry: entry,
          duration: duration,
          slow: slow,
        ),
        const SizedBox(height: 12),
        FerretOverviewTimingCard(entry: entry),
        const SizedBox(height: 12),
        FerretOverviewSizeCard(entry: entry),
      ],
    );
  }
}
