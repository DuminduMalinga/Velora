import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/models/product.dart';
import 'package:velora/services/cart_storage.dart';
import 'package:velora/state/shop_state.dart';

void main() {
  test('cart survives a save and load round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = CartStorage();
    final product = Product(
      id: 7,
      title: 'Lamp',
      price: 20,
      discountPercentage: 10,
      stock: 5,
      thumbnail: 'https://example.com/lamp.png',
    );
    final shop = ShopState()..add(product, null, 2);
    await storage.save(shop.lines);

    final restored = ShopState()..restoreLines(await CartStorage().load());
    expect(restored.itemCount, 2);
    expect(restored.lines.single.product.title, 'Lamp');
    expect(restored.subtotal, shop.subtotal);
  });

  test('corrupt saved data yields an empty cart', () async {
    SharedPreferences.setMockInitialValues({'velora_cart_v1': 'not json'});
    expect(await CartStorage().load(), isEmpty);
  });

  test('favorites survive a save and load round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final product = Product(id: 3, title: 'Chair', price: 50);
    final shop = ShopState()..toggleFavorite(3, product: product);
    await CartStorage().saveFavorites(shop.favoriteProducts);

    final restored = ShopState()
      ..restoreFavorites(await CartStorage().loadFavorites());
    expect(restored.favorites, {3});
    expect(restored.favoriteProducts.single.title, 'Chair');
  });

  test('products without a currency display as LKR', () {
    final product = Product(id: 1, title: 'Lamp', price: 20);
    expect(product.formattedPrice, 'LKR 20.00');
  });
}
