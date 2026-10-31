import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/data/product_repository.dart';
import 'package:velora/main.dart';
import 'package:velora/models/product.dart';
import 'package:velora/screens/product_details_screen.dart';
import 'package:velora/state/shop_state.dart';

class DetailsRepository implements ProductRepository {
  DetailsRepository(this.fetch);
  final Future<List<Product>> Function() fetch;
  @override
  Future<List<Product>> fetchProducts() => fetch();
}

// Test fixtures only; the app never provides a fallback catalog.
Product fixture() => Product.fromJson({
  'id': 'api-product',
  'name': 'API product title',
  'price': 30,
  'description': 'Description from response',
  'category': 'API category',
  'currency': 'USD',
  'stock': 4,
  'rating': {'rate': 4.7, 'count': 8},
  'variations': [
    {'id': 'variant-id', 'name': 'API variation', 'price': 42, 'stock': 2},
    {'id': 'sold-id', 'name': 'Sold variation', 'stock': 0},
  ],
});

Widget details(ProductRepository repository, ShopState shop) => MaterialApp(
  theme: ThemeData.dark(useMaterial3: true),
  home: ProductDetailsScreen(
    productId: 'api-product',
    repository: repository,
    shop: shop,
  ),
);

void main() {
  test('Maps optional API fields and enforces variant and aggregate stock', () {
    final product = fixture();
    final shop = ShopState();
    expect(product.rating, 4.7);
    expect(product.reviewCount, 8);
    expect(shop.add(product, null, 1), isFalse);
    expect(shop.add(product, product.variations.last, 1), isFalse);
    expect(shop.add(product, product.variations.first, 2), isTrue);
    expect(shop.add(product, product.variations.first, 1), isFalse);
    final line = shop.lines.single;
    expect(line.productId, 'api-product');
    expect(line.variation!.id, 'variant-id');
    expect(line.unitPrice, 42);
    expect(line.quantity, 2);
    final unknown = Product.fromJson({
      'id': 'unknown',
      'name': 'Unknown',
      'price': 3,
    });
    expect(shop.add(unknown, null, 1), isFalse);
    final other = ProductVariation(id: 'other', name: 'Other', stock: 8);
    final capped = Product(
      id: product.id,
      name: product.name,
      price: 30,
      stock: 3,
      variations: [other],
    );
    expect(shop.remaining(capped, other), 1);
    expect(shop.add(capped, other, 2), isFalse);
    shop.dispose();
  });

  testWidgets(
    'Loads API details, selects variant price and adds bounded quantity',
    (tester) async {
      tester.view.physicalSize = const Size(360, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = ShopState();
      final pending = Completer<List<Product>>();
      await tester.pumpWidget(
        details(DetailsRepository(() => pending.future), shop),
      );
      expect(find.bySemanticsLabel('Loading product'), findsOneWidget);
      pending.complete([fixture()]);
      await tester.pumpAndSettle();
      expect(find.text('API product title'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('API variation'), 220);
      await tester.tap(find.text('API variation'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byTooltip('Increase quantity'), 150);
      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pump();
      final increase = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == 'Increase quantity',
        ),
      );
      expect(increase.onPressed, isNull);
      await tester.scrollUntilVisible(find.text('Add to Cart'), 160);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();
      expect(shop.lines.single.unitPrice, 42);
      expect(shop.lines.single.quantity, 2);
      expect(shop.lines.single.variation!.id, 'variant-id');
      expect(find.text('Available quantity is in your bag'), findsOneWidget);
      await tester.tap(find.byTooltip('Add to wishlist'));
      await tester.pump();
      expect(shop.favorites, contains('api-product'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Details retries errors and shows missing product state', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      details(
        DetailsRepository(() async {
          if (++attempts == 1) throw Exception('Offline');
          return [];
        }),
        ShopState(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load this product'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Product unavailable'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets(
    'Home card opens details and related products navigate by API ID',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = DetailsRepository(
        () async => [
          fixture(),
          const Product(
            id: 'related-id',
            name: 'Related response title',
            price: 5,
            category: 'API category',
            stock: 1,
          ),
        ],
      );
      await tester.pumpWidget(MyApp(repository: repository));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('API product title'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('API product title'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailsScreen), findsOneWidget);
      expect(find.text('Description from response'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Related response title'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Related response title'));
      await tester.pumpAndSettle();
      final screen = tester.widget<ProductDetailsScreen>(
        find.byType(ProductDetailsScreen),
      );
      expect(screen.productId, 'related-id');
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open cart'));
      await tester.pumpAndSettle();
      expect(find.text('Order summary'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();
      expect(find.text('Related response title'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Quantity: 1')), findsOneWidget);
      expect(find.text('5.00'), findsWidgets);
      await tester.tap(find.text('Continue Shopping'));
      await tester.pumpAndSettle();
      expect(find.text('Find your next\nfavorite thing.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
