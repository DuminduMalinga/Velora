import 'package:flutter/material.dart';
import 'data/product_repository.dart';
import 'screens/home_screen.dart';
import 'state/app_settings.dart';
import 'services/profile_image_service.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.repository, this.settings, this.imageService});
  final ProductRepository? repository;
  final AppSettings? settings;
  final ProfileImageService? imageService;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ProductRepository _repository =
      widget.repository ?? ApiProductRepository();
  late final AppSettings _settings = widget.settings ?? AppSettings();
  late final ProfileImageService _imageService =
      widget.imageService ?? GalleryProfileImageService();
  @override
  void dispose() {
    if (widget.repository == null) _repository.dispose();
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _settings,
    builder: (context, _) => MaterialApp(
      title: 'Velora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _settings.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      locale: _settings.systemLanguage ? null : const Locale('en'),
      supportedLocales: const [Locale('en')],
      home: HomeScreen(
        repository: _repository,
        settings: _settings,
        imageService: _imageService,
      ),
    ),
  );
}
