import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class AppSettings extends ChangeNotifier {
  AppSettings({NotificationService? notificationService})
    : _notificationService = notificationService;
  final NotificationService? _notificationService;
  bool notificationBusy = false;
  String? notificationError;
  bool _disposed = false;

  Future<void> restoreNotifications() async {
    if (notificationBusy) return;
    final revision = _notificationRevision;
    bool enabled;
    try {
      enabled = await _notificationService?.restore() ?? false;
    } catch (_) {
      enabled = false;
    }
    if (!_disposed && revision == _notificationRevision) {
      notifications = enabled;
      notifyListeners();
    }
  }

  Future<void> notifyAlert(AppAlert alert) async {
    if (!notifications) return;
    try {
      await _notificationService?.showAlert(alert);
    } catch (_) {
      notificationError =
          'Unable to show notifications. Check your device notification settings.';
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool notifications = false;
  int _notificationRevision = 0;
  bool systemLanguage = true;
  String? name;
  String? email;
  String? phone;
  Uint8List? photo;

  void setDarkMode(bool dark) {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    if (notificationBusy) return;
    _notificationRevision++;
    notificationBusy = true;
    notificationError = null;
    notifyListeners();
    try {
      notifications = await _notificationService?.setEnabled(value) ?? false;
      if (value && !notifications) {
        notificationError =
            'Notifications are not allowed. Enable them for Velora in your device settings.';
      }
    } on UnsupportedError {
      notifications = false;
      notificationError = 'Notifications are available on Android and iOS.';
    } catch (_) {
      notificationError = 'Unable to update notifications. Please try again.';
    } finally {
      notificationBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void setSystemLanguage(bool value) {
    systemLanguage = value;
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String email,
    required String phone,
    Uint8List? photo,
  }) {
    this.name = name.trim().isEmpty ? null : name.trim();
    this.email = email.trim().isEmpty ? null : email.trim();
    this.phone = phone.trim().isEmpty ? null : phone.trim();
    this.photo = photo;
    notifyListeners();
  }
}
