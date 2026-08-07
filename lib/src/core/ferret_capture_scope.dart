/// Suppresses lower-level `dart:io` capture while Dio / package:http record.
///
/// Dio and `package:http` both use `dart:io` under the hood. Without this,
/// one logical call appears twice in Ferret (once as Dio/http, once as dart:io).
class FerretCaptureScope {
  FerretCaptureScope._();

  static int _depth = 0;

  /// Whether dart:io capture should skip recording.
  static bool get isSuppressed => _depth > 0;

  /// Runs [action] while dart:io capture is suppressed.
  static Future<T> runSuppressed<T>(Future<T> Function() action) async {
    _depth++;
    try {
      return await action();
    } finally {
      _depth--;
    }
  }

  /// Sync variant for interceptor hooks that must stay synchronous.
  static void push() => _depth++;

  /// Pairs with [push].
  static void pop() {
    if (_depth > 0) _depth--;
  }

  /// Test helper.
  static void resetForTest() => _depth = 0;
}
