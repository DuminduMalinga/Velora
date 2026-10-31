import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/screens/cart_screen.dart';
import 'package:velora/state/shop_state.dart';

void main() {
  for (final width in [360.0, 1000.0]) {
    testWidgets('Empty cart and Continue Shopping at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shop = ShopState();
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: CartScreen(
            shop: shop,
            onContinueShopping: () => continued = true,
          ),
        ),
      );
      expect(find.text('Your bag is a blank canvas.'), findsOneWidget);
      await tester.tap(find.text('Continue Shopping'));
      expect(continued, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      shop.dispose();
    });
  }
}
