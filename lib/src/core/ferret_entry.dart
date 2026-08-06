import '../config/http_client_type.dart';

/// One captured HTTP call.
class FerretEntry {
  FerretEntry({
    required this.id,
    required this.client,
    required this.method,
    required this.url,
    required this.requestHeaders,
    required this.startTime,
    this.requestBody,
    this.statusCode,
    this.responseHeaders,
    this.responseBody,
    this.endTime,
    this.sizeBytes,
    this.error,
  });

  final String id;
  final HttpClientType client;
  final String method;
  final Uri url;
  final Map<String, String> requestHeaders;
  final Object? requestBody;
  final DateTime startTime;

  final int? statusCode;
  final Map<String, String>? responseHeaders;
  final Object? responseBody;
  final DateTime? endTime;
  final int? sizeBytes;
  final String? error;

  Duration? get duration => endTime?.difference(startTime);

  bool get isFailed =>
      error != null || (statusCode != null && statusCode! >= 400);

  bool get isPending => endTime == null && error == null;

  bool isSlow(Duration threshold) {
    final d = duration;
    return d != null && d > threshold;
  }

  String get host => url.host;

  FerretEntry copyWith({
    String? id,
    HttpClientType? client,
    String? method,
    Uri? url,
    Map<String, String>? requestHeaders,
    Object? requestBody,
    DateTime? startTime,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Object? responseBody,
    DateTime? endTime,
    int? sizeBytes,
    String? error,
    bool clearError = false,
  }) {
    return FerretEntry(
      id: id ?? this.id,
      client: client ?? this.client,
      method: method ?? this.method,
      url: url ?? this.url,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      requestBody: requestBody ?? this.requestBody,
      startTime: startTime ?? this.startTime,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      endTime: endTime ?? this.endTime,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() {
    return 'FerretEntry($method $url → ${statusCode ?? error ?? 'pending'})';
  }
}
