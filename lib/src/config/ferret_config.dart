import 'http_client_type.dart';

/// Configuration for [Ferret.install].
///
/// Defaults are safe for day-one install: on in debug/profile, off in release
/// unless [enableInRelease] is explicitly set.
class FerretConfig {
  /// Master switch. When `false`, Ferret is a no-op even in debug.
  final bool enabled;

  /// Explicit opt-in to run in release builds. Default `false`.
  final bool enableInRelease;

  /// When active in release, print a console banner and show an on-screen tag.
  final bool showReleaseWarning;

  /// Maximum captured calls retained in memory (ring buffer).
  final int maxEntries;

  /// Capture request/response bodies.
  final bool captureBody;

  /// Floating bubble starts minimized.
  final bool startMinimized;

  /// Which client stacks to intercept.
  final Set<HttpClientType> clients;

  /// Requests slower than this are flagged as slow.
  final Duration slowThreshold;

  /// Optional LAN mirror port. `null` disables the mirror server.
  final int? mirrorPort;

  const FerretConfig({
    this.enabled = true,
    this.enableInRelease = false,
    this.showReleaseWarning = true,
    this.maxEntries = 500,
    this.captureBody = true,
    this.startMinimized = true,
    this.clients = const {
      HttpClientType.dio,
      HttpClientType.http,
      HttpClientType.dartIo,
    },
    this.slowThreshold = const Duration(seconds: 2),
    this.mirrorPort,
  }) : assert(maxEntries > 0, 'maxEntries must be > 0');

  FerretConfig copyWith({
    bool? enabled,
    bool? enableInRelease,
    bool? showReleaseWarning,
    int? maxEntries,
    bool? captureBody,
    bool? startMinimized,
    Set<HttpClientType>? clients,
    Duration? slowThreshold,
    int? mirrorPort,
    bool clearMirrorPort = false,
  }) {
    return FerretConfig(
      enabled: enabled ?? this.enabled,
      enableInRelease: enableInRelease ?? this.enableInRelease,
      showReleaseWarning: showReleaseWarning ?? this.showReleaseWarning,
      maxEntries: maxEntries ?? this.maxEntries,
      captureBody: captureBody ?? this.captureBody,
      startMinimized: startMinimized ?? this.startMinimized,
      clients: clients ?? this.clients,
      slowThreshold: slowThreshold ?? this.slowThreshold,
      mirrorPort: clearMirrorPort ? null : (mirrorPort ?? this.mirrorPort),
    );
  }

  @override
  String toString() {
    return 'FerretConfig('
        'enabled: $enabled, '
        'enableInRelease: $enableInRelease, '
        'showReleaseWarning: $showReleaseWarning, '
        'maxEntries: $maxEntries, '
        'captureBody: $captureBody, '
        'startMinimized: $startMinimized, '
        'clients: $clients, '
        'slowThreshold: $slowThreshold, '
        'mirrorPort: $mirrorPort'
        ')';
  }
}
