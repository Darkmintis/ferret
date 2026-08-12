import 'package:flutter/material.dart';

import '../widgets/ferret_empty_state.dart';
import '../widgets/ferret_section_card.dart';

/// Error tab for a captured HTTP call.
class FerretErrorTab extends StatelessWidget {
  const FerretErrorTab({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = error?.trim() ?? '';

    if (text.isEmpty) {
      return const FerretEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No error',
        message: 'This call completed without an error.',
      );
    }

    return ColoredBox(
      color: scheme.surface,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          FerretSectionCard(
            title: 'Error',
            children: [
              SelectableText(
                text,
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
