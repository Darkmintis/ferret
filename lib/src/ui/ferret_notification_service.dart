import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/ferret_config.dart';
import '../core/ferret_stats.dart';
import '../core/ferret_store.dart';

/// Ongoing notification with live call / error counts (Alice-style).
///
/// No-op on web. Requires notification permission on Android 13+.
class FerretNotificationService {
  FerretNotificationService();

  static const _channelId = 'ferret_inspector';
  static const _channelName = 'Ferret';
  static const _notificationId = 7474;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  FerretStore? _store;
  FerretConfig? _config;
  bool _started = false;
  bool _showReleaseTitle = false;
  Timer? _debounce;

  bool get isStarted => _started;

  Future<void> start({
    required FerretStore store,
    required FerretConfig config,
    bool showReleaseTitle = false,
  }) async {
    if (kIsWeb || _started) return;

    _store = store;
    _config = config;
    _showReleaseTitle = showReleaseTitle;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Live HTTP inspector stats from Ferret',
          importance: Importance.low,
        ),
      );
    }

    _store!.addListener(_onStoreChanged);
    _started = true;
    await _publish();
  }

  Future<void> stop() async {
    _debounce?.cancel();
    _debounce = null;
    _store?.removeListener(_onStoreChanged);
    if (_started) {
      await _plugin.cancel(_notificationId);
    }
    _started = false;
    _store = null;
    _config = null;
  }

  void _onStoreChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_publish());
    });
  }

  Future<void> _publish() async {
    final store = _store;
    final config = _config;
    if (!_started || store == null || config == null) return;

    final stats = FerretStats.fromStore(store.entries, config);
    final title =
        _showReleaseTitle ? 'Ferret ACTIVE (release)' : 'Ferret';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Live HTTP inspector stats from Ferret',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      category: AndroidNotificationCategory.status,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.show(
      _notificationId,
      title,
      stats.statusLine,
      details,
    );
  }
}
