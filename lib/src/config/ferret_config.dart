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

  /// Show a live notification with call / error counts while the app is open.
  ///
  /// Cleared when the app is backgrounded or closed. Default `true`.
  /// Set `false` to disable. No-op on web.
  final bool showNotification;

  /// Maximum captured calls retained in memory (ring buffer).
  final int maxEntries;

  /// Capture request/response bodies.
  final bool captureBody;

  /// Floating bubble starts minimized.
  ///
  /// Kept for config compatibility; the bubble is always a simple count badge.
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
    this.showNotification = true,
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
    bool? showNotification,
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
      showNotification: showNotification ?? this.showNotification,
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
        'showNotification: $showNotification, '
        'maxEntries: $maxEntries, '
        'captureBody: $captureBody, '
        'startMinimized: $startMinimized, '
        'clients: $clients, '
        'slowThreshold: $slowThreshold, '
        'mirrorPort: $mirrorPort'
        ')';
  }
}
