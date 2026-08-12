/// Sorts and classifies HTTP headers for the inspector UI.
abstract final class FerretHeaderDisplay {
  static const _priority = <String>[
    'authorization',
    'proxy-authorization',
    'content-type',
    'accept',
    'accept-language',
    'cookie',
    'set-cookie',
    'user-agent',
    'x-api-key',
    'api-key',
    'x-request-id',
    'x-correlation-id',
  ];

  /// Important headers first, then alphabetical.
  static List<MapEntry<String, String>> sorted(Map<String, String> headers) {
    final entries = headers.entries.toList()
      ..sort((a, b) {
        final aRank = _rank(a.key);
        final bRank = _rank(b.key);
        if (aRank != bRank) return aRank.compareTo(bRank);
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return entries;
  }

  static bool isImportant(String name) {
    final lower = name.toLowerCase();
    if (_priority.contains(lower)) return true;
    return lower.contains('auth') ||
        lower.contains('token') ||
        lower.contains('api-key') ||
        lower.contains('apikey');
  }

  static int _rank(String name) {
    final lower = name.toLowerCase();
    final index = _priority.indexOf(lower);
    if (index >= 0) return index;
    if (isImportant(name)) return _priority.length;
    return _priority.length + 1;
  }
}
