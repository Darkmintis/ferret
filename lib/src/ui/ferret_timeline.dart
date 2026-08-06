import 'package:flutter/material.dart';

import '../core/ferret_entry.dart';

/// Simple waterfall / timeline of captured calls.
class FerretTimeline extends StatelessWidget {
  const FerretTimeline({
    super.key,
    required this.entries,
    required this.slowThreshold,
    this.onTap,
  });

  final List<FerretEntry> entries;
  final Duration slowThreshold;
  final ValueChanged<FerretEntry>? onTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No requests yet'));
    }

    final completed = entries.where((e) => e.endTime != null).toList();
    if (completed.isEmpty) {
      return const Center(child: Text('Waiting for responses…'));
    }

    final earliest = completed
        .map((e) => e.startTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = completed
        .map((e) => e.endTime!)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final totalMs =
        latest.difference(earliest).inMilliseconds.clamp(1, 1 << 30);

    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completed.length,
      itemBuilder: (context, index) {
        final entry = completed[index];
        final start =
            entry.startTime.difference(earliest).inMilliseconds / totalMs;
        final width =
            (entry.duration?.inMilliseconds ?? 0).clamp(1, totalMs) / totalMs;
        final color = entry.isFailed
            ? scheme.error
            : entry.isSlow(slowThreshold)
                ? scheme.tertiary
                : scheme.primary;

        return InkWell(
          onTap: onTap == null ? null : () => onTap!(entry),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.method} ${entry.host}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 14,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          Positioned(
                            left: constraints.maxWidth * start,
                            child: Container(
                              width: (constraints.maxWidth * width)
                                  .clamp(4.0, constraints.maxWidth),
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.duration?.inMilliseconds ?? 0} ms',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
