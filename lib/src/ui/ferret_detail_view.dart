import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ferret_entry.dart';
import '../export/curl_exporter.dart';
import 'detail/ferret_error_tab.dart';
import 'detail/ferret_links_tab.dart';
import 'detail/ferret_message_tab.dart';
import 'detail/ferret_overview_tab.dart';
import 'ferret_export_sheet.dart';
import 'ferret_link_sheet.dart';
import 'ferret_theme.dart';
import 'ferret_ui_feedback.dart';

/// Full raw request/response detail.
class FerretDetailView extends StatelessWidget {
  const FerretDetailView({
    super.key,
    required this.entry,
    required this.slowThreshold,
    this.onOpenUrl,
  });

  final FerretEntry entry;
  final Duration slowThreshold;

  /// Opens a tapped link (see `FerretConfig.onOpenUrl`).
  final FutureOr<void> Function(Uri url)? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return FerretTheme.wrap(context, (context) {
      final duration = entry.duration;
      final slow = entry.isSlow(slowThreshold);

      return FerretLinkScope(
        onOpenUrl: onOpenUrl,
        child: DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              title: Text('${entry.method} ${entry.statusCode ?? '…'}'),
              actions: [
                IconButton(
                  tooltip: 'Copy as cURL',
                  onPressed: () => _copyCurl(context, entry),
                  icon: const Icon(Icons.copy_rounded),
                ),
                IconButton(
                  tooltip: 'Share HAR',
                  onPressed: () =>
                      FerretExportSheet.showCall(context, entry: entry),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
              bottom: const TabBar(
                labelPadding: EdgeInsets.zero,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Request'),
                  Tab(text: 'Response'),
                  Tab(text: 'Links'),
                  Tab(text: 'Error'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                FerretOverviewTab(entry: entry, duration: duration, slow: slow),
                FerretMessageTab(kind: FerretMessageKind.request, entry: entry),
                FerretMessageTab(
                  kind: FerretMessageKind.response,
                  entry: entry,
                ),
                FerretLinksTab(entry: entry),
                FerretErrorTab(error: entry.error),
              ],
            ),
          ),
        ),
      );
    });
  }

  static Future<void> _copyCurl(BuildContext context, FerretEntry entry) async {
    await FerretUiFeedback.run(
      context,
      action: () async {
        final curl = const CurlExporter().export(entry);
        await Clipboard.setData(ClipboardData(text: curl));
      },
      successMessage: 'cURL copied',
      failurePrefix: 'Copy failed',
    );
  }
}
