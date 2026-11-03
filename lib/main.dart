import 'package:flutter/material.dart';
import 'data/product_repository.dart';
import 'screens/home_screen.dart';
import 'state/app_settings.dart';
import 'services/profile_image_service.dart';
import 'services/notification_service.dart';
import 'services/catalog_alert_service.dart';
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final ProductRepository _repository =
      widget.repository ?? ApiProductRepository();
  late final AppSettings _settings =
      widget.settings ??
      AppSettings(notificationService: LocalNotificationService());
  late final ProfileImageService _imageService =
      widget.imageService ?? GalleryProfileImageService();
  late final CatalogAlertService _alerts = CatalogAlertService(
    repository: _repository,
    notify: _settings.notifyAlert,
  );
  bool _foreground = true;

  void _syncAlerts() {
    if (_foreground && _settings.notifications) {
      _alerts.start();
    } else {
      _alerts.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_syncAlerts);
    _syncAlerts();
    if (widget.settings == null) _settings.restoreNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncAlerts();
    if (state == AppLifecycleState.resumed && !_settings.notificationBusy) {
      _settings.restoreNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_syncAlerts);
    _alerts.stop();
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
