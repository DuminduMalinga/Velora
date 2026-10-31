import 'package:flutter_test/flutter_test.dart';
import 'package:velora/data/product_repository.dart';
import 'package:velora/state/shop_state.dart';

const live = bool.fromEnvironment('RUN_LIVE_API_TESTS');

void main() {
  test('Empty cart has no fabricated products or shipping', () {
    final shop = ShopState();
    expect(shop.lines, isEmpty);
    expect(shop.favorites, isEmpty);
    expect(shop.subtotal, 0);
    expect(shop.total, 0);
    expect(shop.shipping, isNull);
    expect(shop.setQuantity(-1, null, 1), isFalse);
    shop.dispose();
  });

  test(
    'Live product cart uses discounted API price, stock and integer-cent totals',
    () async {
      final repository = ApiProductRepository();
      final shop = ShopState();
      addTearDown(repository.dispose);
      addTearDown(shop.dispose);
      final page = await repository.getProducts();
      final product = page.products.firstWhere((p) => (p.stock ?? 0) >= 2);
      expect(shop.add(product, null, 1), isTrue);
      expect(shop.lines.single.productId, product.id);
      expect(shop.lines.single.unitPrice, product.effectivePrice);
      expect(shop.setQuantity(product.id, null, 2), isTrue);
      expect(shop.subtotal, (product.effectivePrice * 100).round() * 2 / 100);
      expect(shop.total, shop.subtotal);
      expect(shop.setQuantity(product.id, null, 0), isFalse);
      expect(shop.setQuantity(product.id, null, product.stock! + 1), isFalse);
      expect(shop.itemCount, 2);
      expect(shop.setQuantity(product.id, null, 1), isTrue);
      expect(shop.itemCount, 1);
      expect(shop.subtotal, product.effectivePrice);
      shop.toggleFavorite(product.id, product: product);
      expect(shop.favoriteProducts.single.id, product.id);
      shop.toggleFavorite(product.id);
      expect(shop.favoriteProducts, isEmpty);
      expect(shop.favorites, isEmpty);
      await shop.refreshCart(repository);
      expect(shop.lines.single.productId, product.id);
      shop.removeLine(product.id, null);
      expect(shop.lines, isEmpty);
      expect(shop.total, 0);
    },
    skip: !live,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
