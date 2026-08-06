import 'package:flutter/foundation.dart';

import '../config/ferret_config.dart';

/// Resolves whether Ferret should be active for a given config + build mode.
///
/// Extracted for unit testing without depending on [kReleaseMode] alone.
class FerretActivation {
  const FerretActivation({
    required this.active,
    required this.showReleaseWarning,
  });

  /// Whether interceptors, store, and overlay should run.
  final bool active;

  /// Whether to print the release banner and show the red on-screen tag.
  final bool showReleaseWarning;

  /// Compute activation from [config] and build mode.
  factory FerretActivation.resolve(
    FerretConfig config, {
    bool? isReleaseMode,
  }) {
    final release = isReleaseMode ?? kReleaseMode;

    if (release) {
      if (!config.enableInRelease) {
        return const FerretActivation(
          active: false,
          showReleaseWarning: false,
        );
      }
      return FerretActivation(
        active: true,
        showReleaseWarning: config.showReleaseWarning,
      );
    }

    // debug / profile
    return FerretActivation(
      active: config.enabled,
      showReleaseWarning: false,
    );
  }
}

/// Loud console banner printed once when Ferret runs in a release build.
void printFerretReleaseWarning() {
  const banner = '''
╔════════════════════════════════════════════════════╗
║  ⚠️  FERRET IS ACTIVE IN A RELEASE BUILD            ║
║  You explicitly set enableInRelease: true.          ║
║  Real user network traffic is being captured on     ║
║  this device. Disable before shipping to users.     ║
╚════════════════════════════════════════════════════╝''';
  debugPrint(banner);
}
