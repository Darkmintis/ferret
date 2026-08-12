import 'package:ferret/ferret.dart';

FerretEntry testEntry(
  String id, {
  int? status = 200,
  String method = 'GET',
  HttpClientType client = HttpClientType.http,
  Uri? url,
  Map<String, String> requestHeaders = const {},
  Object? requestBody,
  Map<String, String>? responseHeaders,
  Object? responseBody,
  DateTime? startTime,
  DateTime? endTime,
  int? sizeBytes,
  String? error,
}) {
  return FerretEntry(
    id: id,
    client: client,
    method: method,
    url: url ?? Uri.parse('https://example.com/$id'),
    requestHeaders: requestHeaders,
    requestBody: requestBody,
    startTime: startTime ?? DateTime.utc(2026, 1, 1, 12),
    statusCode: status,
    responseHeaders: responseHeaders,
    responseBody: responseBody,
    endTime: endTime,
    sizeBytes: sizeBytes,
    error: error,
  );
}

FerretEntry completedEntry(
  String id, {
  int status = 200,
  String method = 'GET',
  Duration duration = const Duration(milliseconds: 120),
  Object? responseBody,
  Map<String, String>? responseHeaders,
  Map<String, String> requestHeaders = const {},
  Object? requestBody,
  String? error,
}) {
  final start = DateTime.utc(2026, 1, 1, 12);
  return testEntry(
    id,
    status: status,
    method: method,
    requestHeaders: requestHeaders,
    requestBody: requestBody,
    responseHeaders: responseHeaders,
    responseBody: responseBody,
    startTime: start,
    endTime: start.add(duration),
    error: error,
  );
}
