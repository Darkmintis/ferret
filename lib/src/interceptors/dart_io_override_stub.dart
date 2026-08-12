import '../core/ferret_engine.dart';

/// No-op on platforms without `dart:io` (e.g. web).
class FerretDartIoOverride {
  FerretDartIoOverride._();

  static void install(FerretEngine engine) {}

  static void uninstall() {}
}
