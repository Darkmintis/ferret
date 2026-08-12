import '../core/ferret_entry.dart';
import 'ferret_redaction.dart';

/// Builds a cURL command from a [FerretEntry].
class CurlExporter {
  const CurlExporter();

  String export(FerretEntry entry, {bool redact = false}) {
    final headers = redact
        ? FerretRedaction.headers(entry.requestHeaders)
        : entry.requestHeaders;
    final url = redact
        ? FerretRedaction.url(entry.url).toString()
        : entry.url.toString();

    final buffer = StringBuffer('curl -X ${entry.method}');
    buffer.write(' \'${_escape(url)}\'');

    headers.forEach((key, value) {
      buffer.write(' \\\n  -H \'${_escape('$key: $value')}\'');
    });

    final body = entry.requestBody;
    if (body != null) {
      final Object redactedOrRaw =
          redact ? FerretRedaction.body(body) : body;
      final payload = FerretRedaction.stringifyBody(redactedOrRaw);
      if (payload.isNotEmpty) {
        buffer.write(' \\\n  --data-raw \'${_escape(payload)}\'');
      }
    }

    return buffer.toString();
  }

  static String _escape(String value) =>
      value.replaceAll("'", r"'\''");
}
