import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF4275FF),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFF4275FF) : const Color(0xFF2855DB),
          secondary: dark ? const Color(0xFF85AAFF) : const Color(0xFF2855DB),
          surface: dark ? const Color(0xFF111D34) : Colors.white,
          onSurface: dark ? const Color(0xFFF2F5FF) : const Color(0xFF202B3F),
        );
    final background = dark ? const Color(0xFF080F20) : const Color(0xFFF4F6FA);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF0D172B) : Colors.white,
        indicatorColor: dark
            ? const Color(0xFF244CC4)
            : const Color(0xFFE2EAFF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 1,
        shadowColor: const Color(0x14000000),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}

/// Maps the established navy palette to light surfaces without changing layouts.
extension VeloraColors on BuildContext {
  Color adaptive(int darkColor) {
    if (Theme.of(this).brightness == Brightness.dark) return Color(darkColor);
    return switch (darkColor) {
      0xFF080F20 => const Color(0xFFF4F6FA),
      0xFF111D34 || 0xFF101B30 || 0xFF0D172B => Colors.white,
      0xDD0D172B || 0xDD080F20 => const Color(0xEEFFFFFF),
      0xFF19253B ||
      0xFF20304B ||
      0xFF14243D ||
      0xFF152542 ||
      0xFF0B1528 ||
      0xFF0E1A32 => const Color(0xFFEBEFF6),
      0xFF2B4168 || 0xFF293953 || 0xFF35425D => const Color(0xFFD4DEED),
      0xFF94A3BF ||
      0xFFADB9D0 ||
      0xFF8392AE ||
      0xFFAAB8D1 ||
      0xFF8D9AB5 => const Color(0xFF5E6C82),
      0xFF85AAFF ||
      0xFFACC7FF ||
      0xFFBBD0FF ||
      0xFFA8C1FF => const Color(0xFF2855CB),
      0xFF244CC4 => const Color(0xFFE2EAFF),
      _ => Color(darkColor),
    };
  }
}
