import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import '../../core/ferret_store.dart';
import '../ferret_detail_view.dart';

/// Pushes a live-updating detail route for a captured call.
abstract final class FerretDetailRoute {
  static void open(
    BuildContext context, {
    required FerretStore store,
    required FerretEntry entry,
    required Duration slowThreshold,
  }) {
    final entryId = entry.id;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 120),
        reverseTransitionDuration: const Duration(milliseconds: 100),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final live = store.getById(entryId) ?? entry;
              return FerretDetailView(
                entry: live,
                slowThreshold: slowThreshold,
              );
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
