import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import 'ferret_call_card.dart';

/// Scrollable list of captured HTTP calls.
class FerretCallsList extends StatelessWidget {
  const FerretCallsList({
    super.key,
    required this.entries,
    required this.storeEmpty,
    required this.filteredEmpty,
    required this.slowThreshold,
    required this.onOpen,
  });

  final List<FerretEntry> entries;
  final bool storeEmpty;
  final bool filteredEmpty;
  final Duration slowThreshold;
  final ValueChanged<FerretEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final message = storeEmpty
          ? 'No HTTP calls yet.\nFire a request to see it here.'
          : filteredEmpty
          ? 'No calls match your filters.\nTry adjusting search or chips.'
          : 'No HTTP calls yet.\nFire a request to see it here.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 24 + bottomInset),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FerretCallCard(
            entry: entry,
            slowThreshold: slowThreshold,
            onOpen: () => onOpen(entry),
          ),
        );
      },
    );
  }
}
