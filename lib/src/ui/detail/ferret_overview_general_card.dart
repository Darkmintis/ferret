import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import '../widgets/ferret_section_card.dart';

class FerretOverviewGeneralCard extends StatelessWidget {
  const FerretOverviewGeneralCard({
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
    return FerretSectionCard(
      title: 'General',
      children: [
        FerretMetricRow(label: 'Method', value: entry.method),
        FerretMetricRow(label: 'Server', value: entry.host),
        FerretMetricRow(
          label: 'Path',
          value: entry.url.path.isEmpty ? '/' : entry.url.path,
        ),
        if (entry.url.hasQuery)
          FerretMetricRow(label: 'Query', value: entry.url.query),
        FerretMetricRow(label: 'Client', value: entry.client.name),
        if (entry.statusCode != null)
          FerretMetricRow(label: 'Status', value: '${entry.statusCode}'),
        if (duration != null)
          FerretMetricRow(
            label: 'Duration',
            value: '${duration!.inMilliseconds} ms',
            emphasis: slow,
          ),
        FerretMetricRow(
          label: 'Secure',
          value: entry.url.scheme == 'https' ? 'Yes' : 'No',
        ),
      ],
    );
  }
}
