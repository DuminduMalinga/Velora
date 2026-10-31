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
  double get subtotal => (unitPrice * 100).round() * quantity / 100;
}

class ShippingQuote {
  const ShippingQuote({required this.amount, this.currency});
  final double amount;
  final String? currency;
}

class ShopState extends ChangeNotifier {
  final Set<String> _favorites = {};
  final Map<(String, String?), CartLine> _lines = {};
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<CartLine> get lines => List.unmodifiable(_lines.values);
  ShippingQuote? _shipping;
  ShippingQuote? get shipping => _shipping;
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);
  Map<String?, double> get subtotals {
    final amounts = <String?, int>{};
    for (final line in _lines.values) {
      amounts.update(
        line.product.currency,
        (cents) => cents + (line.unitPrice * 100).round() * line.quantity,
        ifAbsent: () => (line.unitPrice * 100).round() * line.quantity,
      );
    }
    return amounts.map((currency, cents) => MapEntry(currency, cents / 100));
  }

  bool get hasMixedCurrencies => subtotals.length > 1;
  double? get subtotal =>
      hasMixedCurrencies ? null : subtotals.values.firstOrNull ?? 0;
  double? get total => subtotal == null
      ? null
      : ((subtotal! * 100).round() + ((_shipping?.amount ?? 0) * 100).round()) /
            100;

  // A quote is supplied by a future shipping service, never guessed locally.
  bool setShippingQuote(ShippingQuote quote) {
    if (_lines.isEmpty ||
        hasMixedCurrencies ||
        !quote.amount.isFinite ||
        quote.amount < 0 ||
        quote.currency != subtotals.keys.single) {
      return false;
    }
    _shipping = quote;
    notifyListeners();
    return true;
  }

  bool setQuantity(String productId, String? variationId, int quantity) {
    final key = (productId, variationId);
    final line = _lines[key];
    if (line == null || quantity < 1) return false;
    final delta = quantity - line.quantity;
    if (delta > 0 && delta > remaining(line.product, line.variation)) {
      return false;
    }
    if (delta == 0) return true;
    _lines[key] = CartLine(
      product: line.product,
      variation: line.variation,
      quantity: quantity,
    );
    _shipping = null;
    notifyListeners();
    return true;
  }

  void removeLine(String productId, String? variationId) {
    if (_lines.remove((productId, variationId)) == null) return;
    _shipping = null;
    notifyListeners();
  }

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
    _shipping = null;
    notifyListeners();
    return true;
  }

  void removeProduct(String id) {
    _lines.removeWhere((key, value) => key.$1 == id);
    _shipping = null;
    notifyListeners();
  }
}
