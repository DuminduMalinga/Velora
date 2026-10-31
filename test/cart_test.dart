import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/product.dart';
import 'package:velora/screens/cart_screen.dart';
import 'package:velora/state/shop_state.dart';

// API-like fixtures are used only in tests, never as runtime catalog data.
const product = Product(
  id: 'server-id',
  name: 'Response product',
  price: 19.99,
  currency: 'USD',
  stock: 3,
);

void main() {
  test(
    'Quantity limits, per-variant removal, shipping and monetary totals',
    () {
      final shop = ShopState();
      expect(shop.add(product, null, 1), isTrue);
      expect(shop.setQuantity(product.id, null, 0), isFalse);
      expect(shop.setQuantity(product.id, null, -1), isFalse);
      expect(shop.setQuantity(product.id, null, 4), isFalse);
      expect(shop.setQuantity('missing', null, 1), isFalse);
      expect(shop.setQuantity(product.id, null, 3), isTrue);
      expect(shop.subtotal, 59.97);
      expect(
        shop.setShippingQuote(
          const ShippingQuote(amount: 4.99, currency: 'EUR'),
        ),
        isFalse,
      );
      expect(
        shop.setShippingQuote(const ShippingQuote(amount: -1, currency: 'USD')),
        isFalse,
      );
      expect(
        shop.setShippingQuote(
          const ShippingQuote(amount: 4.99, currency: 'USD'),
        ),
        isTrue,
      );
      expect(shop.total, 64.96);
      shop.toggleFavorite(product.id);
      expect(shop.shipping, isNotNull);
      shop.setQuantity(product.id, null, 2);
      expect(shop.shipping, isNull);
      expect(shop.total, 39.98);
      const a = ProductVariation(
        id: 'a',
        name: 'Option A',
        price: 3.5,
        stock: 3,
      );
      const b = ProductVariation(id: 'b', name: 'Option B', price: 4, stock: 3);
      const variants = Product(
        id: 'variants',
        name: 'Variants',
        price: 3,
        currency: 'USD',
        stock: 3,
        variations: [a, b],
      );
      shop.add(variants, a, 1);
      shop.add(variants, b, 2);
      expect(shop.setQuantity(variants.id, a.id, 2), isFalse);
      shop.removeLine(variants.id, b.id);
      expect(
        shop.lines.where((line) => line.variation?.id == a.id),
        hasLength(1),
      );
      expect(shop.setQuantity(variants.id, a.id, 2), isTrue);
      expect(shop.subtotal, 46.98);
      shop.dispose();
    },
  );

  test('Mixed currencies are never combined into a total', () {
    final shop = ShopState()..add(product, null, 1);
    shop.add(
      const Product(
        id: 'euro',
        name: 'Other response',
        price: 10,
        currency: 'EUR',
        stock: 1,
      ),
      null,
      1,
    );
    expect(shop.hasMixedCurrencies, isTrue);
    expect(shop.subtotal, isNull);
    expect(shop.total, isNull);
    expect(shop.subtotals, {'USD': 19.99, 'EUR': 10.0});
  });

  testWidgets(
    'Cart responds to quantities, stock limits, removal and empty CTA on phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = ShopState()..add(product, null, 1);
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: CartScreen(
            shop: shop,
            onContinueShopping: () => continued = true,
          ),
        ),
      );
      final decrease = find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.tooltip == 'Decrease quantity of Response product',
      );
      final increase = find.byTooltip('Increase quantity of Response product');
      expect(tester.widget<IconButton>(decrease).onPressed, isNull);
      await tester.tap(increase);
      await tester.pump();
      expect(shop.total, 39.98);
      expect(find.bySemanticsLabel(RegExp('Quantity: 2')), findsOneWidget);
      await tester.tap(increase);
      await tester.pump();
      expect(shop.total, 59.97);
      expect(find.text('Available quantity reached'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) =>
                    w is IconButton &&
                    w.tooltip == 'Increase quantity of Response product',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Decrease quantity of Response product'));
      await tester.pump();
      expect(shop.itemCount, 2);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Your bag is a blank canvas.'), findsOneWidget);
      expect(shop.total, 0);
      await tester.tap(find.text('Continue Shopping'));
      expect(continued, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Quote updates total; checkout explains unavailable service without clearing cart',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = ShopState()..add(product, null, 2);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: CartScreen(shop: shop, onContinueShopping: () {}),
        ),
      );
      expect(find.text('Estimated total'), findsOneWidget);
      expect(find.text('Not yet quoted'), findsOneWidget);
      shop.setShippingQuote(const ShippingQuote(amount: 4.99, currency: 'USD'));
      await tester.pump();
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('USD 44.97'), findsOneWidget);
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();
      expect(find.text('Checkout is not available yet'), findsOneWidget);
      await tester.tap(find.text('Back to bag'));
      await tester.pumpAndSettle();
      expect(shop.itemCount, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
