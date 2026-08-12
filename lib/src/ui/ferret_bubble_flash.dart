import 'dart:async';

import '../core/ferret_store.dart';

/// Tracks failed-call count and drives the bubble error flash.
class FerretBubbleFlash {
  FerretBubbleFlash(this.store) : _lastFailed = _count(store);

  final FerretStore store;
  static const flashDuration = Duration(seconds: 2);

  int _lastFailed;
  bool errorFlash = false;
  Timer? _timer;

  void dispose() => _timer?.cancel();

  void onStoreChanged(void Function() refresh) {
    final failed = _count(store);
    if (failed > _lastFailed) _trigger(refresh);
    _lastFailed = failed;
  }

  void _trigger(void Function() refresh) {
    _timer?.cancel();
    errorFlash = true;
    refresh();
    _timer = Timer(flashDuration, () {
      errorFlash = false;
      refresh();
    });
  }

  static int _count(FerretStore store) =>
      store.entries.where((e) => e.isFailed).length;
}
