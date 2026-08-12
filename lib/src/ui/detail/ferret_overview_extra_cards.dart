import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import '../../core/ferret_message_size.dart';
import '../widgets/ferret_section_card.dart';

class FerretOverviewTimingCard extends StatelessWidget {
  const FerretOverviewTimingCard({super.key, required this.entry});

  final FerretEntry entry;

  @override
  Widget build(BuildContext context) {
    return FerretSectionCard(
      title: 'Timing',
      children: [
        FerretMetricRow(
          label: 'Started',
          value: entry.startTime.toIso8601String(),
        ),
        if (entry.endTime != null)
          FerretMetricRow(
            label: 'Finished',
            value: entry.endTime!.toIso8601String(),
          ),
      ],
    );
  }
}

class FerretOverviewSizeCard extends StatelessWidget {
  const FerretOverviewSizeCard({super.key, required this.entry});

  final FerretEntry entry;

  @override
  Widget build(BuildContext context) {
    final requestBytes = FerretMessageSize.bytes(
      headers: entry.requestHeaders,
      body: entry.requestBody,
    );
    final responseBytes = FerretMessageSize.bytes(
      headers: entry.responseHeaders ?? const {},
      body: entry.responseBody,
    );

    return FerretSectionCard(
      title: 'Size',
      children: [
        FerretMetricRow(
          label: 'Bytes sent',
          value: FerretMessageSize.formatBytes(requestBytes),
        ),
        FerretMetricRow(
          label: 'Bytes received',
          value: FerretMessageSize.formatBytes(responseBytes),
        ),
        if (entry.sizeBytes != null)
          FerretMetricRow(
            label: 'Total',
            value: FerretMessageSize.formatBytes(entry.sizeBytes!),
          ),
      ],
    );
  }
}
