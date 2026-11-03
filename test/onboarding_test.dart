import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/data/product_repository.dart';
import 'package:velora/main.dart';
import 'package:velora/models/product.dart';
import 'package:velora/screens/home_screen.dart';
import 'package:velora/screens/splash_screen.dart';
import 'package:velora/screens/welcome_screen.dart';
import 'package:velora/state/app_settings.dart';
import 'package:velora/theme/app_theme.dart';

class UnavailableCatalog extends ProductRepository {
  int requests = 0;
  @override
  Future<ProductPage> getProducts({
    int limit = 20,
    int skip = 0,
    String? query,
    String? category,
    String? sortBy,
    String order = 'asc',
  }) async {
    requests++;
    throw const SocketException('Offline');
  }

  @override
  Future<Product?> getProduct(int id) async => null;
  @override
  Future<List<ProductCategory>> getCategories() async => [];
}

void main() {
  setUpAll(() async {
    const fontPath = String.fromEnvironment('ONBOARDING_PREVIEW_FONT');
    if (fontPath.isNotEmpty) {
      final loader = FontLoader('Roboto')
        ..addFont(
          File(
            fontPath,
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
      final icons = File(
        '${File(fontPath).parent.path}/materialicons-regular.otf',
      );
      if (icons.existsSync()) {
        await (FontLoader('MaterialIcons')..addFont(
              icons.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            ))
            .load();
      }
    }
  });
  testWidgets(
    'Splash completes, welcome opens exactly one existing Home even offline',
    (tester) async {
      final repository = UnavailableCatalog();
      final settings = AppSettings();
      await tester.pumpWidget(
        MyApp(repository: repository, settings: settings),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(repository.requests, 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      await tester.ensureVisible(find.text('Start Shopping'));
      await tester.tap(find.text('Start Shopping'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(repository.requests, 1);
      expect(
        tester.widget<HomeScreen>(find.byType(HomeScreen)).settings,
        same(settings),
      );
      expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      settings.dispose();
    },
  );

  for (final dark in [true, false]) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(1000, 700),
      const Size(600, 320),
    ]) {
      testWidgets(
        'Welcome fits $size, dark=$dark, with accessible navigation',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(size.width == 320 ? 1.6 : 1),
                ),
                child: child!,
              ),
              home: RepaintBoundary(
                key: captureKey,
                child: WelcomeScreen(
                  homeBuilder: (_) =>
                      const Scaffold(body: Text('Existing Home')),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('CAPTURE_ONBOARDING') &&
              size.width == 390) {
            await tester.runAsync(() async {
              final boundary =
                  captureKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 2);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'build/previews/welcome-${dark ? 'dark' : 'light'}.png',
              );
              file.parent.createSync(recursive: true);
              file.writeAsBytesSync(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.ensureVisible(find.text('Start Shopping'));
          await tester.tap(find.text('Start Shopping'));
          await tester.pumpAndSettle();
          expect(find.text('Existing Home'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets(
    'Reduced motion skips splash animation and early removal disposes ticker',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: SplashScreen(homeBuilder: (_) => const Scaffold()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: SplashScreen(homeBuilder: (_) => const Scaffold()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );
}
