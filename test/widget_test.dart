import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/main.dart';
import 'package:velora/data/product_repository.dart';
import 'package:velora/models/product.dart';

class TestRepository implements ProductRepository {
  TestRepository(this.fetch);
  final Future<List<Product>> Function() fetch;
  @override
  Future<List<Product>> fetchProducts() => fetch();
}

void main() {
  testWidgets('API products render at narrow widths and favorites update', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Test-only response fixture; no catalog data ships with the app.
    final product = Product.fromJson({
      'id': 'fixture-id',
      'name': 'API response title',
      'price': 12.5,
      'category': 'API response category',
      'currency': 'USD',
      'featured': true,
    });
    await tester.pumpWidget(
      MyApp(repository: TestRepository(() async => [product])),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to wishlist').first);
    await tester.pump();
    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();
    expect(find.text('API response title'), findsOneWidget);
    expect(find.text('USD 12.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Remove from wishlist'));
    await tester.pumpAndSettle();
    expect(find.text('Save something you love'), findsOneWidget);
  });

  testWidgets('Shows loading then empty state without fabricated products', (
    tester,
  ) async {
    final pending = Completer<List<Product>>();
    await tester.pumpWidget(
      MyApp(repository: TestRepository(() => pending.future)),
    );
    expect(find.text('All'), findsNothing);
    expect(find.byType(AnimatedBuilder), findsWidgets);
    pending.complete([]);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No products found'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No products found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed fetch can be retried', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MyApp(
        repository: TestRepository(() async {
          attempts++;
          if (attempts == 1) throw Exception('Offline');
          return [];
        }),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Retry'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('No products found'), findsOneWidget);
  });

  testWidgets('Unconfigured store shows setup state', (tester) async {
    await tester.pumpWidget(
      MyApp(
        repository: TestRepository(() async => throw const ApiNotConfigured()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('The collection is coming soon'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('The collection is coming soon'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
