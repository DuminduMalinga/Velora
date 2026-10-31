import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool notifications = false;
  bool systemLanguage = true;
  String? name;
  String? email;
  String? phone;
  Uint8List? photo;

  void setDarkMode(bool dark) {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setNotifications(bool value) {
    notifications = value;
    notifyListeners();
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
