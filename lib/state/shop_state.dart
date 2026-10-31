import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.variation,
  });
  final Product product;
  final ProductVariation? variation;
  final int quantity;
  String get productId => product.id;
  double get unitPrice => variation?.price ?? product.price;
}

class ShopState extends ChangeNotifier {
  final Set<String> _favorites = {};
  final Map<(String, String?), CartLine> _lines = {};
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<CartLine> get lines => List.unmodifiable(_lines.values);
  Map<String, int> get quantities {
    final result = <String, int>{};
    for (final line in _lines.values) {
      result.update(
        line.productId,
        (n) => n + line.quantity,
        ifAbsent: () => line.quantity,
      );
    }
    return result;
  }

  void toggleFavorite(String id) {
    if (!_favorites.add(id)) _favorites.remove(id);
    notifyListeners();
  }

  int remaining(Product product, ProductVariation? variation) {
    final available = product.availableStock(variation);
    if (available == null) return 0;
    final lineQuantity = _lines[(product.id, variation?.id)]?.quantity ?? 0;
    final variantRemaining = available - lineQuantity;
    final totalRemaining = product.stock == null
        ? variantRemaining
        : product.stock! - (quantities[product.id] ?? 0);
    final remaining = variantRemaining < totalRemaining
        ? variantRemaining
        : totalRemaining;
    return remaining < 0 ? 0 : remaining;
  }

  bool add(Product product, ProductVariation? variation, int quantity) {
    if (product.variations.isNotEmpty &&
        !product.variations.contains(variation)) {
      return false;
    }
    if (product.variations.isEmpty && variation != null) return false;
    if (quantity < 1 || quantity > remaining(product, variation)) return false;
    final key = (product.id, variation?.id);
    _lines[key] = CartLine(
      product: product,
      variation: variation,
      quantity: (_lines[key]?.quantity ?? 0) + quantity,
    );
    notifyListeners();
    return true;
  }

  void removeProduct(String id) {
    _lines.removeWhere((key, value) => key.$1 == id);
    notifyListeners();
  }
}
