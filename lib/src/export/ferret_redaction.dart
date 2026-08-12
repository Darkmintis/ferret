import 'dart:convert';

/// Shared secret redaction for exports (cURL and HAR).
class FerretRedaction {
  const FerretRedaction._();

  static bool isSensitiveHeader(String key) {
    final lower = key.toLowerCase();
    return lower == 'authorization' ||
        lower == 'proxy-authorization' ||
        lower == 'cookie' ||
        lower == 'set-cookie' ||
        lower.contains('token') ||
        lower.contains('api-key') ||
        lower.contains('apikey') ||
        lower.contains('secret') ||
        lower == 'x-api-key';
  }

  static bool isSensitiveQueryKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('token') ||
        lower.contains('key') ||
        lower.contains('secret') ||
        lower.contains('password') ||
        lower.contains('auth') ||
        lower.contains('session') ||
        lower.contains('sig');
  }

  static Map<String, String> headers(Map<String, String> headers) {
    return {
      for (final e in headers.entries)
        e.key: isSensitiveHeader(e.key) ? '***' : e.value,
    };
  }

  static Map<String, String> queryParameters(Map<String, String> params) {
    return {
      for (final e in params.entries)
        e.key: isSensitiveQueryKey(e.key) ? '***' : e.value,
    };
  }

  /// URL with sensitive query values redacted (keeps structure for HAR).
  static Uri url(Uri input) {
    if (input.queryParameters.isEmpty) return input;
    return input.replace(queryParameters: queryParameters(input.queryParameters));
  }

  static Object body(Object body) {
    if (body is Map) {
      return <Object?, Object?>{
        for (final e in body.entries)
          e.key: _redactMapValue(e.key, e.value),
      };
    }
    if (body is List) {
      return <Object?>[
        for (final item in body) _redactNested(item),
      ];
    }
    if (body is String) {
      return body
          .replaceAll(
            RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
            '***@***',
          )
          .replaceAllMapped(
            RegExp(r'(Bearer\s+)\S+', caseSensitive: false),
            (match) => '${match.group(1)}***',
          );
    }
    return body;
  }

  static Object? _redactMapValue(Object? key, Object? value) {
    if (_isSensitiveBodyKey('$key')) {
      return '***';
    }
    return _redactNested(value);
  }

  static bool _isSensitiveBodyKey(String key) {
    final k = key.toLowerCase();
    const exact = {
      'password',
      'passwd',
      'token',
      'secret',
      'email',
      'authorization',
      'access_token',
      'refresh_token',
      'id_token',
      'api_key',
      'apikey',
    };
    if (exact.contains(k)) return true;
    return k.endsWith('_password') ||
        k.endsWith('_token') ||
        k.endsWith('_secret') ||
        k.contains('password') ||
        k.contains('secret');
  }

  static Object? _redactNested(Object? value) {
    if (value is Map) {
      return body(value);
    }
    if (value is List) {
      return body(value);
    }
    return value;
  }

  static String stringifyBody(Object body) {
    if (body is String) return body;
    if (body is List<int>) {
      try {
        return utf8.decode(body);
      } on Object {
        return base64Encode(body);
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } on Object {
      return body.toString();
    }
  }
}
