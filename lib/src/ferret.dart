import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config/ferret_config.dart';
import 'config/http_client_type.dart';
import 'core/ferret_activation.dart';
import 'core/ferret_capture_scope.dart';
import 'core/ferret_engine.dart';
import 'core/ferret_entry.dart';
import 'core/ferret_store.dart';
import 'export/curl_exporter.dart';
import 'export/har_exporter.dart';
import 'export/share_exporter.dart';
import 'interceptors/dart_io_override_stub.dart'
    if (dart.library.io) 'interceptors/dart_io_override.dart';
import 'interceptors/dio_interceptor.dart';
import 'interceptors/http_wrapper.dart';
import 'ui/ferret_bubble.dart';
import 'ui/ferret_dashboard.dart';

/// Ferret — modern, production-safe HTTP inspector for Flutter.
///
/// ```dart
/// void main() {
///   Ferret.install();
///   runApp(const MyApp());
/// }
/// ```
class Ferret {
  Ferret._();

  static FerretConfig _config = const FerretConfig();
  static FerretStore? _store;
  static FerretEngine? _engine;
  static FerretDioInterceptor? _dioInterceptor;
  static FerretActivation _activation = const FerretActivation(
    active: false,
    showReleaseWarning: false,
  );
  static OverlayEntry? _overlayEntry;
  static bool _installed = false;
  static final ValueNotifier<bool> _inspectorOpen = ValueNotifier<bool>(false);
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Whether the Ferret inspector screen is currently open.
  static bool get isInspectorOpen => _inspectorOpen.value;

  /// Whether Ferret is currently capturing traffic.
  static bool get isActive => _activation.active;

  /// Whether the permanent release warning tag should be shown.
  static bool get showReleaseWarning => _activation.showReleaseWarning;

  /// Current config (empty defaults before [install]).
  static FerretConfig get config => _config;

  /// Captured entries store. `null` when inactive.
  static FerretStore? get store => _store;

  /// Dio interceptor — add to existing Dio instances:
  /// `dio.interceptors.add(Ferret.dioInterceptor)`.
  ///
  /// Returns a no-op interceptor when Ferret is inactive.
  static Interceptor get dioInterceptor {
    if (!_activation.active || _dioInterceptor == null) {
      return const _NoopInterceptor();
    }
    return _dioInterceptor!;
  }

  /// One-line install. Safe to call before [runApp].
  ///
  /// Calling again tears down the previous install and applies [config].
  static void install({FerretConfig config = const FerretConfig()}) {
    if (_installed) {
      _tearDown();
    }

    _config = config;
    _activation = FerretActivation.resolve(config);

    if (!_activation.active) {
      _installed = true;
      return;
    }

    _store = FerretStore(maxEntries: config.maxEntries);
    _engine = FerretEngine(store: _store!, config: config);
    _dioInterceptor = FerretDioInterceptor(_engine!);

    if (config.clients.contains(HttpClientType.dartIo) && !kIsWeb) {
      FerretDartIoOverride.install(_engine!);
    }

    if (_activation.showReleaseWarning) {
      printFerretReleaseWarning();
    }

    _installed = true;
  }

  /// Creates a Dio instance with Ferret already attached.
  static Dio createDio([BaseOptions? options]) {
    final dio = Dio(options);
    dio.interceptors.add(dioInterceptor);
    return dio;
  }

  /// Wraps a `package:http` client. Returns [client] unchanged when inactive.
  static http.Client wrapClient(http.Client client) {
    if (!_activation.active ||
        _engine == null ||
        !_config.clients.contains(HttpClientType.http)) {
      return client;
    }
    return FerretHttpClient(client, _engine!);
  }

  /// Inserts the floating bubble overlay.
  ///
  /// Prefer [builder] on your [MaterialApp] so this happens automatically.
  static void showOverlay(BuildContext context) {
    if (!_activation.active || _store == null || _engine == null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    hideOverlay();
    _overlayEntry = OverlayEntry(builder: (context) => _bubble());
    overlay.insert(_overlayEntry!);
  }

  /// Removes the floating bubble if present.
  static void hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Opens the dashboard as a full-screen route.
  static Future<void> openDashboard([BuildContext? context]) async {
    if (!_activation.active || _store == null) return;
    if (_inspectorOpen.value) return;

    final nav =
        navigatorKey.currentState ??
        (context != null
            ? Navigator.maybeOf(context, rootNavigator: true)
            : null);

    if (nav == null) {
      debugPrint(
        'Ferret: no Navigator found. '
        'Set MaterialApp(navigatorKey: Ferret.navigatorKey, builder: Ferret.builder).',
      );
      return;
    }

    _inspectorOpen.value = true;
    try {
      await nav.push(
        PageRouteBuilder<void>(
          opaque: true,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 120),
          reverseTransitionDuration: const Duration(milliseconds: 100),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FerretDashboard(
              store: _store!,
              config: _config,
              onClear: clear,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );
    } finally {
      _inspectorOpen.value = false;
    }
  }

  static Widget _bubble() {
    return ListenableBuilder(
      listenable: _inspectorOpen,
      builder: (context, _) {
        if (_inspectorOpen.value) {
          return const SizedBox.shrink();
        }
        return FerretBubble(
          store: _store!,
          showReleaseTag: _activation.showReleaseWarning,
          onOpen: () {
            unawaited(openDashboard());
          },
        );
      },
    );
  }

  /// Clears captured entries.
  static void clear() => _store?.clear();

  /// Export a single entry as cURL.
  static String toCurl(FerretEntry entry, {bool redact = false}) {
    return const CurlExporter().export(entry, redact: redact);
  }

  /// Export the session as HAR JSON.
  static String toHar({bool redact = false}) {
    final entries = _store?.entries ?? const <FerretEntry>[];
    return const HarExporter().export(entries, redact: redact);
  }

  /// Share the session as HAR via the platform share sheet.
  static Future<void> shareSession({bool redact = false}) async {
    final entries = _store?.entries ?? const <FerretEntry>[];
    await const ShareExporter().shareSessionHar(entries, redact: redact);
  }

  /// Share one captured call as cURL.
  static Future<void> shareCurl(
    FerretEntry entry, {
    bool redact = false,
  }) async {
    await const ShareExporter().shareCurl(entry, redact: redact);
  }

  /// Attach Ferret to [MaterialApp.builder] / [CupertinoApp.builder].
  static Widget builder(BuildContext context, Widget? child) {
    if (!_activation.active || _store == null) {
      return child ?? const SizedBox.shrink();
    }
    return Stack(
      fit: StackFit.expand,
      children: [child ?? const SizedBox.shrink(), _bubble()],
    );
  }

  /// Fully tear down Ferret (tests / hot restart helpers).
  @visibleForTesting
  static void resetForTest() {
    _tearDown();
    _installed = false;
    _activation = const FerretActivation(
      active: false,
      showReleaseWarning: false,
    );
    _config = const FerretConfig();
  }

  static void _tearDown() {
    hideOverlay();
    _inspectorOpen.value = false;
    FerretDartIoOverride.uninstall();
    _dioInterceptor = null;
    _engine = null;
    _store?.dispose();
    _store = null;
    FerretCaptureScope.resetForTest();
  }

  /// Whether [install] has been called in this isolate.
  static bool get isInstalled => _installed;
}

class _NoopInterceptor extends Interceptor {
  const _NoopInterceptor();
}
