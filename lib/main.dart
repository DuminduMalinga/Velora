import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/cart_storage.dart';
import 'state/shop_state.dart';
import 'data/product_repository.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_settings.dart';
import 'services/profile_image_service.dart';
import 'services/notification_service.dart';
import 'services/catalog_alert_service.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.repository,
    this.settings,
    this.imageService,
    this.cartStorage,
  });
  final CartStorage? cartStorage;
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
  late final ShopState _shop = ShopState();
  late final CartStorage _cartStorage = widget.cartStorage ?? CartStorage();
  bool _cartRestored = false;
  bool _foreground = true;

  Future<void> _restoreCart() async {
    final saved = await _cartStorage.load();
    if (!mounted) return;
    final favorites = await _cartStorage.loadFavorites();
    if (!mounted) return;
    if (saved.isNotEmpty && _shop.lines.isEmpty) _shop.restoreLines(saved);
    if (favorites.isNotEmpty) _shop.restoreFavorites(favorites);
    _cartRestored = true;
  }

  // Never write before the saved cart is read, or an empty cart would wipe it.
  void _saveCart() {
    if (_cartRestored && !_shop.paymentInProgress) {
      _cartStorage.save(_shop.lines);
      _cartStorage.saveFavorites(_shop.favoriteProducts);
    }
  }

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
    _shop.addListener(_saveCart);
    _restoreCart();
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
    _shop.removeListener(_saveCart);
    _shop.dispose();
    if (widget.repository == null) _repository.dispose();
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _settings,
    builder: (context, _) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: _settings),
        ChangeNotifierProvider<ShopState>.value(value: _shop),
        Provider<ProductRepository>.value(value: _repository),
      ],
      child: MaterialApp(
        title: 'Velora',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _settings.themeMode,
        themeAnimationDuration: const Duration(milliseconds: 250),
        locale: _settings.systemLanguage ? null : const Locale('en'),
        supportedLocales: const [Locale('en')],
        home: SplashScreen(
          homeBuilder: (_) => HomeScreen(
            repository: _repository,
            settings: _settings,
            imageService: _imageService,
            shop: _shop,
          ),
        ),
      ),
    ),
  );
}
