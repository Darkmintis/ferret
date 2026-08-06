import '../core/ferret_entry.dart';

/// Filter state for the dashboard list.
class FerretFilter {
  const FerretFilter({
    this.query = '',
    this.methods = const {},
    this.failedOnly = false,
    this.slowOnly = false,
    this.domain,
  });

  final String query;
  final Set<String> methods;
  final bool failedOnly;
  final bool slowOnly;
  final String? domain;

  static const empty = FerretFilter();

  bool get isActive =>
      query.trim().isNotEmpty ||
      methods.isNotEmpty ||
      failedOnly ||
      slowOnly ||
      (domain != null && domain!.isNotEmpty);

  FerretFilter copyWith({
    String? query,
    Set<String>? methods,
    bool? failedOnly,
    bool? slowOnly,
    String? domain,
    bool clearDomain = false,
  }) {
    return FerretFilter(
      query: query ?? this.query,
      methods: methods ?? this.methods,
      failedOnly: failedOnly ?? this.failedOnly,
      slowOnly: slowOnly ?? this.slowOnly,
      domain: clearDomain ? null : (domain ?? this.domain),
    );
  }

  List<FerretEntry> apply(
    List<FerretEntry> entries, {
    required Duration slowThreshold,
  }) {
    return entries.where((entry) {
      if (failedOnly && !entry.isFailed) return false;
      if (slowOnly && !entry.isSlow(slowThreshold)) return false;
      if (methods.isNotEmpty && !methods.contains(entry.method)) return false;
      if (domain != null &&
          domain!.isNotEmpty &&
          !entry.host.contains(domain!)) {
        return false;
      }
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return true;
      final haystack = [
        entry.method,
        entry.url.toString(),
        entry.statusCode?.toString() ?? '',
        entry.error ?? '',
        entry.host,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
  }
}
