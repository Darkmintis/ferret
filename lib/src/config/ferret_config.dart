import 'http_client_type.dart';

/// Configuration for [Ferret.install].
///
/// Defaults are safe for day-one install: on in debug/profile, off in release
/// unless [enableInRelease] is explicitly set.
///
/// When Ferret is active in a release build, the console banner and red
/// on-screen tag are **always** shown and cannot be disabled.
class FerretConfig {
  /// Master switch. When `false`, Ferret is a no-op even in debug.
  final bool enabled;

  /// Explicit opt-in to run in release builds. Default `false`.
  ///
  /// When `true`, Ferret always prints a loud console warning and shows a
  /// permanent red "FERRET ACTIVE" tag. That warning cannot be turned off.
  final bool enableInRelease;

  /// Maximum captured calls retained in memory (ring buffer).
  final int maxEntries;

  /// Capture request/response bodies.
  final bool captureBody;

  /// Which client stacks to intercept.
  final Set<HttpClientType> clients;

  /// Requests slower than this are flagged as slow.
  final Duration slowThreshold;

  const FerretConfig({
    this.enabled = true,
    this.enableInRelease = false,
    this.maxEntries = 500,
    this.captureBody = true,
    this.clients = const {
      HttpClientType.dio,
      HttpClientType.http,
      HttpClientType.dartIo,
    },
    this.slowThreshold = const Duration(seconds: 2),
  }) : assert(maxEntries > 0, 'maxEntries must be > 0');

  FerretConfig copyWith({
    bool? enabled,
    bool? enableInRelease,
    int? maxEntries,
    bool? captureBody,
    Set<HttpClientType>? clients,
    Duration? slowThreshold,
  }) {
    return FerretConfig(
      enabled: enabled ?? this.enabled,
      enableInRelease: enableInRelease ?? this.enableInRelease,
      maxEntries: maxEntries ?? this.maxEntries,
      captureBody: captureBody ?? this.captureBody,
      clients: clients ?? this.clients,
      slowThreshold: slowThreshold ?? this.slowThreshold,
    );
  }

  @override
  String toString() {
    return 'FerretConfig('
        'enabled: $enabled, '
        'enableInRelease: $enableInRelease, '
        'maxEntries: $maxEntries, '
        'captureBody: $captureBody, '
        'clients: $clients, '
        'slowThreshold: $slowThreshold'
        ')';
  }
}
