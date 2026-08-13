import 'package:flutter/material.dart';

import '../../core/ferret_entry.dart';
import '../../core/ferret_message_size.dart';
import '../widgets/ferret_section_card.dart';
import 'ferret_body_section.dart';
import 'ferret_headers_section.dart';

enum FerretMessageKind { request, response }

/// Request or response tab with metadata, headers, and body.
class FerretMessageTab extends StatelessWidget {
  const FerretMessageTab({
    super.key,
    required this.kind,
    required this.entry,
  });

  final FerretMessageKind kind;
  final FerretEntry entry;

  @override
  Widget build(BuildContext context) {
    final isRequest = kind == FerretMessageKind.request;
    final headers = isRequest
        ? entry.requestHeaders
        : (entry.responseHeaders ?? const <String, String>{});
    final body = isRequest ? entry.requestBody : entry.responseBody;
    final bytes = FerretMessageSize.bytes(headers: headers, body: body);
    final contentType =
        FerretMessageSize.header(headers, 'content-type') ?? '—';

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          FerretSectionCard(
            title: isRequest ? 'Request' : 'Response',
            children: [
              FerretMetricRow(
                label: isRequest ? 'Started' : 'Received',
                value: isRequest
                    ? entry.startTime.toIso8601String()
                    : (entry.endTime?.toIso8601String() ?? 'Pending…'),
              ),
              FerretMetricRow(
                label: isRequest ? 'Bytes sent' : 'Bytes received',
                value: FerretMessageSize.formatBytes(bytes),
              ),
              if (!isRequest && entry.statusCode != null)
                FerretMetricRow(label: 'Status', value: '${entry.statusCode}'),
              FerretMetricRow(label: 'Content-Type', value: contentType),
            ],
          ),
          const SizedBox(height: 12),
          FerretHeadersSection(headers: headers),
          const SizedBox(height: 12),
          FerretBodySection(body: body),
        ],
      ),
    );
  }
}
