import 'dart:async';

import 'package:flutter/widgets.dart';

import 'http_client_type.dart';

/// Configuration for [Ferret.install].
///
/// Defaults are safe for day-one install: on in debug/profile, off in release
/// unless [enableInRelease] is explicitly set.
///
/// When Ferret is active in a release build, the console banner and red
/// bubble border are **always** shown and cannot be disabled.
class FerretConfig {
  /// Master switch. When `false`, Ferret is a no-op even in debug.
  final bool enabled;

  /// Explicit opt-in to run in release builds. Default `false`.
  ///
  /// When `true`, Ferret always prints a loud console warning and shows a
  /// permanent red border around the bubble. That warning cannot be turned off.
  final bool enableInRelease;

  /// Maximum captured calls retained in memory (ring buffer).
  final int maxEntries;

  /// Capture request/response bodies.
  final bool captureBody;

  /// Largest body kept per request/response, in bytes. Longer bodies are cut
  /// to this size and marked as truncated; sizes still report the full length.
  /// `null` keeps whole bodies (watch memory with large JSON or images).
  final int? maxBodyBytes;

  /// Which client stacks to intercept.
  final Set<HttpClientType> clients;

  /// Requests slower than this are flagged as slow.
  final Duration slowThreshold;

  /// Optional navigator key for [MaterialApp.router] / GoRouter.
  ///
  /// Pass your app's existing key (the same one given to GoRouter). When null,
  /// Ferret uses its built-in [Ferret.navigatorKey].
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Opens a link tapped in the inspector, e.g. with `url_launcher`:
  /// `onOpenUrl: (uri) => launchUrl(uri)`. When null, the link sheet offers
  /// Copy and Preview only, so Ferret adds no launcher dependency.
  final FutureOr<void> Function(Uri url)? onOpenUrl;

  const FerretConfig({
    this.enabled = true,
    this.enableInRelease = false,
    this.maxEntries = 500,
    this.captureBody = true,
    this.maxBodyBytes = defaultMaxBodyBytes,
    this.clients = const {
      HttpClientType.dio,
      HttpClientType.http,
      HttpClientType.dartIo,
    },
    this.slowThreshold = const Duration(seconds: 2),
    this.navigatorKey,
    this.onOpenUrl,
  }) : assert(maxEntries > 0, 'maxEntries must be > 0'),
       assert(
         maxBodyBytes == null || maxBodyBytes > 0,
         'maxBodyBytes must be > 0 or null',
       );

  /// Default [maxBodyBytes]: 256 KB.
  static const int defaultMaxBodyBytes = 256 * 1024;

  FerretConfig copyWith({
    bool? enabled,
    bool? enableInRelease,
    int? maxEntries,
    bool? captureBody,
    int? maxBodyBytes,
    Set<HttpClientType>? clients,
    Duration? slowThreshold,
    GlobalKey<NavigatorState>? navigatorKey,
    FutureOr<void> Function(Uri url)? onOpenUrl,
  }) {
    return FerretConfig(
      enabled: enabled ?? this.enabled,
      enableInRelease: enableInRelease ?? this.enableInRelease,
      maxEntries: maxEntries ?? this.maxEntries,
      captureBody: captureBody ?? this.captureBody,
      maxBodyBytes: maxBodyBytes ?? this.maxBodyBytes,
      clients: clients ?? this.clients,
      slowThreshold: slowThreshold ?? this.slowThreshold,
      navigatorKey: navigatorKey ?? this.navigatorKey,
      onOpenUrl: onOpenUrl ?? this.onOpenUrl,
    );
  }

  @override
  String toString() {
    return 'FerretConfig('
        'enabled: $enabled, '
        'enableInRelease: $enableInRelease, '
        'maxEntries: $maxEntries, '
        'captureBody: $captureBody, '
        'maxBodyBytes: $maxBodyBytes, '
        'clients: $clients, '
        'slowThreshold: $slowThreshold, '
        'navigatorKey: ${navigatorKey != null}, '
        'onOpenUrl: ${onOpenUrl != null}'
        ')';
  }
}
