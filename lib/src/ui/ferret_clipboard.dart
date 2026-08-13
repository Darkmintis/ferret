import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ferret_ui_feedback.dart';

/// Clipboard helpers for Ferret detail sections.
abstract final class FerretClipboard {
  static Future<void> copy(
    BuildContext context, {
    required String text,
    required String successMessage,
    String emptyMessage = 'Nothing to copy',
  }) async {
    if (text.trim().isEmpty) {
      FerretUiFeedback.showError(context, emptyMessage);
      return;
    }

    await FerretUiFeedback.run(
      context,
      action: () async {
        await Clipboard.setData(ClipboardData(text: text));
      },
      successMessage: successMessage,
      failurePrefix: 'Copy failed',
    );
  }

  static Widget copyIcon({
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: const Icon(Icons.copy_rounded, size: 18),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
