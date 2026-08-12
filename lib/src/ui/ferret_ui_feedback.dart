import 'package:flutter/material.dart';

/// Snackbar helpers with safe error handling for Ferret UI actions.
abstract final class FerretUiFeedback {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, isError: true);
  }

  static Future<void> run(
    BuildContext context, {
    required Future<void> Function() action,
    required String successMessage,
    String failurePrefix = 'Action failed',
  }) async {
    try {
      await action();
      if (context.mounted && successMessage.isNotEmpty) {
        showSuccess(context, successMessage);
      }
    } on Object catch (error) {
      if (context.mounted) {
        showError(context, '$failurePrefix: $error');
      }
    }
  }

  static void _show(BuildContext context, String message, {required bool isError}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
