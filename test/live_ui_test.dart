import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/data/product_repository.dart';
import 'package:velora/main.dart';
import 'package:velora/screens/cart_screen.dart';
import 'package:velora/screens/checkout_preview_screen.dart';
import 'package:velora/screens/product_details_screen.dart';
import 'package:velora/widgets/product_card.dart';

// Allow actual HTTP requests rather than Flutter's default test HTTP rejection.
class LiveNetwork extends HttpOverrides {}

const live = bool.fromEnvironment('RUN_LIVE_API_TESTS');

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 150; i++) {
    if (ready()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Live UI did not become ready within the network timeout');
}

void main() {
  for (final width in [360.0, 1200.0]) {
    testWidgets('Live shopping and checkout preview at width $width', (
      tester,
    ) async {
      await HttpOverrides.runWithHttpOverrides(() async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = ApiProductRepository();
        await tester.pumpWidget(MyApp(repository: repository));
        await waitFor(
          tester,
          () => find.byType(ChoiceChip).evaluate().isNotEmpty,
        );
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
        await tester.pump(const Duration(milliseconds: 300));
        await waitFor(
          tester,
          () => find.byType(ProductCard).evaluate().isNotEmpty,
        );
        final card = tester.widget<ProductCard>(find.byType(ProductCard).first);
        final product = card.product;
        await tester.tap(find.byType(ProductCard).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await waitFor(
          tester,
          () =>
              find.byType(ProductDetailsScreen).evaluate().isNotEmpty &&
              find.text('About this product').evaluate().isNotEmpty,
        );
        expect(find.text(product.title), findsOneWidget);
        await tester.tap(find.byTooltip('Add to wishlist'));
        await tester.pump();
        expect(find.byTooltip('Remove from wishlist'), findsOneWidget);
        if ((product.stock ?? 0) > 0) {
          await tester.scrollUntilVisible(
            find.text('Add to Cart'),
            220,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -80),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Add to Cart'));
          await tester.pump(const Duration(milliseconds: 300));
          final detailsBadge = tester.widget<Badge>(
            find.descendant(
              of: find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Open cart',
              ),
              matching: find.byType(Badge),
            ),
          );
          expect((detailsBadge.label as Text).data, '1');
          await tester.tap(find.byTooltip('Open cart'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await waitFor(
            tester,
            () => find.byType(CartScreen).evaluate().isNotEmpty,
          );
          expect(find.byType(CartScreen), findsOneWidget);
          expect(find.text(product.title), findsOneWidget);
          expect(find.text(product.formattedPrice), findsWidgets);
          final shop = tester.widget<CartScreen>(find.byType(CartScreen)).shop;
          if (product.stock! >= 2) {
            await tester.tap(
              find.byTooltip('Increase quantity of ${product.title}'),
            );
            await tester.pump();
            expect(shop.itemCount, 2);
            expect(
              shop.subtotal,
              (product.effectivePrice * 100).round() * 2 / 100,
            );
            await tester.tap(
              find.byTooltip('Decrease quantity of ${product.title}'),
            );
            await tester.pump();
            expect(shop.itemCount, 1);
          }
          await tester.scrollUntilVisible(
            find.text('Checkout'),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -120),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Checkout'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.byType(CheckoutPreviewScreen), findsOneWidget);
          expect(
            find.text(CheckoutPreviewScreen.shippingMessage),
            findsOneWidget,
          );
          expect(
            find.text(CheckoutPreviewScreen.paymentMessage),
            findsOneWidget,
          );
          expect(find.text('Quantity: 1'), findsOneWidget);
          expect(shop.itemCount, 1);
          expect(shop.shipping, isNull);
          await tester.pageBack();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(shop.lines.single.productId, product.id);
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, 800),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('Remove'));
          await tester.pumpAndSettle();
          expect(find.text('Remove item?'), findsOneWidget);
          expect(shop.itemCount, 1);
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(shop.itemCount, 1);
          await tester.tap(find.text('Remove'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Your bag is a blank canvas.'), findsOneWidget);
          await tester.tap(find.text('Continue Shopping'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.text('Wishlist'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text(product.title), findsOneWidget);
          await tester.tap(find.byTooltip('Remove from wishlist'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Save something you love'), findsOneWidget);
          final homeBadge = tester.widget<Badge>(
            find.descendant(
              of: find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Open cart',
              ),
              matching: find.byType(Badge),
            ),
          );
          expect(homeBadge.isLabelVisible, isFalse);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        repository.dispose();
      }, LiveNetwork());
    }, skip: !live);
  }
}
