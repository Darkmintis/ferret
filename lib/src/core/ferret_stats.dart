import '../config/ferret_config.dart';
import 'ferret_entry.dart';

/// Aggregate stats for bubble badge and summaries.
class FerretStats {
  const FerretStats({
    required this.total,
    required this.failed,
    required this.slow,
    required this.pending,
  });

  final int total;
  final int failed;
  final int slow;
  final int pending;

  int get succeeded => total - failed - pending;

  factory FerretStats.fromEntries(
    List<FerretEntry> entries, {
    required Duration slowThreshold,
  }) {
    var failed = 0;
    var slow = 0;
    var pending = 0;
    for (final entry in entries) {
      if (entry.isPending) {
        pending++;
      } else if (entry.isFailed) {
        failed++;
      }
      if (entry.isSlow(slowThreshold)) {
        slow++;
      }
    }
    return FerretStats(
      total: entries.length,
      failed: failed,
      slow: slow,
      pending: pending,
    );
  }

  factory FerretStats.fromStore(
    Iterable<FerretEntry> entries,
    FerretConfig config,
  ) {
    return FerretStats.fromEntries(
      entries.toList(growable: false),
      slowThreshold: config.slowThreshold,
    );
  }

  /// Compact label for the floating bubble: call count only.
  String get bubbleLabel => '$total';

  /// Richer status line for the dashboard header / export headers.
  String get statusLine {
    final parts = <String>['$total calls'];
    if (failed > 0) parts.add('$failed failed');
    if (slow > 0) parts.add('$slow slow');
    if (pending > 0) parts.add('$pending pending');
    return parts.join(' · ');
  }
}
