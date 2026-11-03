import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlertType {
  discount(2, 'discounts', 'Discount alerts'),
  newArrival(3, 'new_arrivals', 'New arrivals'),
  appUpdate(4, 'app_updates', 'App updates');

  const AlertType(this.notificationId, this.channelId, this.channelName);
  final int notificationId;
  final String channelId;
  final String channelName;
}

class AppAlert {
  const AppAlert({required this.type, required this.title, required this.body});
  final AlertType type;
  final String title;
  final String body;
}

abstract class NotificationService {
  Future<bool> restore();
  Future<bool> setEnabled(bool enabled);
  Future<void> showAlert(AppAlert alert);
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;
  Future<void> _pending = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initialize() async {
    try {
      await (_initialization ??= _setup());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _setup() async {
    if (!_supported) {
      throw UnsupportedError('Notifications require Android or iOS.');
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> restore() async {
    if (!_supported) return false;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_enabled') ??
        prefs.getBool('bag_notifications') ??
        false)) {
      return false;
    }
    await _initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await ios?.checkPermissions())?.isEnabled ?? false;
  }

  @override
  Future<bool> setEnabled(bool enabled) =>
      _serialize(() => _setEnabled(enabled));

  Future<bool> _setEnabled(bool enabled) async {
    await _initialize();
    var granted = false;
    if (enabled) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      granted = android != null
          ? await android.requestNotificationsPermission() ?? false
          : await ios?.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                ) ??
                false;
    } else {
      await _plugin.cancel(1);
      for (final type in AlertType.values) {
        await _plugin.cancel(type.notificationId);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', granted);
    await prefs.remove('bag_notifications');
    return granted;
  }

  @override
  Future<void> showAlert(AppAlert alert) => _serialize(() => _showAlert(alert));

  Future<void> _showAlert(AppAlert alert) async {
    if (!await restore()) return;
    await _plugin.show(
      alert.type.notificationId,
      alert.title,
      alert.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          alert.type.channelId,
          alert.type.channelName,
          channelDescription: alert.type.channelName,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }
}
