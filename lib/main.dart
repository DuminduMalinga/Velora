import 'package:flutter/material.dart';
import 'data/product_repository.dart';
import 'screens/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.repository});
  final ProductRepository? repository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ProductRepository _repository =
      widget.repository ?? ApiProductRepository();

  @override
  void dispose() {
    if (widget.repository == null) _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Velora',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF080F20),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4275FF),
        secondary: Color(0xFF85AAFF),
        surface: Color(0xFF111D34),
        onSurface: Color(0xFFF2F5FF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF080F20),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111D34),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: HomeScreen(repository: _repository),
  );
}
