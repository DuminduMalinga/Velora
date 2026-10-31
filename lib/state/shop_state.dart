import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../data/product_repository.dart';

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.variation,
  });
  final Product product;
  final ProductVariation? variation;
  final int quantity;
  int get productId => product.id;
  double get unitPrice => variation?.price ?? product.effectivePrice;
  double get subtotal => (unitPrice * 100).round() * quantity / 100;
}

class ShippingQuote {
  const ShippingQuote({required this.amount, this.currency});
  final double amount;
  final String? currency;
}

class ShopState extends ChangeNotifier {
  final Set<int> _favorites = {};
  final Map<int, Product> _knownProducts = {};
  List<Product> get favoriteProducts =>
      _favorites.map((id) => _knownProducts[id]).whereType<Product>().toList();
  final Map<(int, String?), CartLine> _lines = {};
  Set<int> get favorites => Set.unmodifiable(_favorites);
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

  bool setQuantity(int productId, String? variationId, int quantity) {
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

  void removeLine(int productId, String? variationId) {
    if (_lines.remove((productId, variationId)) == null) return;
    _shipping = null;
    notifyListeners();
  }

  Map<int, int> get quantities {
    final result = <int, int>{};
    for (final line in _lines.values) {
      result.update(
        line.productId,
        (n) => n + line.quantity,
        ifAbsent: () => line.quantity,
      );
    }
    return result;
  }

  void toggleFavorite(int id, {Product? product}) {
    if (product != null) _knownProducts[id] = product;
    if (!_favorites.add(id)) _favorites.remove(id);
    notifyListeners();
  }

  void rememberProducts(Iterable<Product> products) {
    for (final product in products) {
      _knownProducts[product.id] = product;
    }
  }

  void reconcile(Product product) {
    _knownProducts[product.id] = product;
    for (final key
        in _lines.keys.where((key) => key.$1 == product.id).toList()) {
      final old = _lines[key]!;
      final variant = key.$2 == null
          ? null
          : product.variations.where((v) => v.id == key.$2).firstOrNull;
      if (key.$2 != null && variant == null) {
        _lines.remove(key);
        continue;
      }
      final available = product.availableStock(variant);
      if (available == 0) {
        _lines.remove(key);
        continue;
      }
      final usedByOthers = _lines.entries
          .where((entry) => entry.key.$1 == product.id && entry.key != key)
          .fold<int>(0, (sum, entry) => sum + entry.value.quantity);
      final cap = product.stock == null
          ? available
          : product.stock! - usedByOthers;
      var quantity = old.quantity;
      if (available != null && quantity > available) quantity = available;
      if (cap != null && quantity > cap) quantity = cap;
      if (quantity < 1) {
        _lines.remove(key);
      } else {
        _lines[key] = CartLine(
          product: product,
          variation: variant,
          quantity: quantity,
        );
      }
    }
    _shipping = null;
    notifyListeners();
  }

  Future<void> refreshCart(ProductRepository repository) async {
    final ids = quantities.keys.toList();
    final products = await Future.wait(ids.map(repository.getProduct));
    for (var i = 0; i < ids.length; i++) {
      if (products[i] == null) {
        removeProduct(ids[i]);
      } else {
        reconcile(products[i]!);
      }
    }
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
    _knownProducts[product.id] = product;
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

  void removeProduct(int id) {
    _lines.removeWhere((key, value) => key.$1 == id);
    _shipping = null;
    notifyListeners();
  }
}
