import 'package:flutter/material.dart';

import 'ferret_ui_feedback.dart';

/// HAR export option tiles shown in a bottom sheet.
class FerretExportOptions extends StatelessWidget {
  const FerretExportOptions({
    super.key,
    required this.title,
    required this.subtitle,
    required this.parentContext,
    required this.onShareHar,
    required this.onCopyHar,
  });

  final String title;
  final String subtitle;
  final BuildContext parentContext;
  final Future<void> Function(bool redact) onShareHar;
  final Future<void> Function(bool redact) onCopyHar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(title: Text(title), subtitle: Text(subtitle)),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Share HAR'),
          subtitle: const Text('Chrome DevTools compatible'),
          onTap: () => _run(context, () => onShareHar(false)),
        ),
        ListTile(
          leading: const Icon(Icons.copy_rounded),
          title: const Text('Copy HAR'),
          onTap: () => _run(
            context,
            () => onCopyHar(false),
            successMessage: 'HAR copied',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Share HAR (redacted)'),
          subtitle: const Text('Masks tokens / auth on export only'),
          onTap: () => _run(context, () => onShareHar(true)),
        ),
        ListTile(
          leading: const Icon(Icons.copy_all_outlined),
          title: const Text('Copy HAR (redacted)'),
          onTap: () => _run(
            context,
            () => onCopyHar(true),
            successMessage: 'Redacted HAR copied',
          ),
        ),
      ],
    );
  }

  Future<void> _run(
    BuildContext sheetContext,
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    Navigator.pop(sheetContext);
    await FerretUiFeedback.run(
      parentContext,
      action: action,
      successMessage: successMessage ?? '',
      failurePrefix: 'Export failed',
    );
  }
}
