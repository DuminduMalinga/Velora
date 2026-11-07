import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../state/shop_state.dart';

/// Saves and restores the shopping cart so it survives app restarts.
class CartStorage {
  CartStorage({SharedPreferences? preferences}) : _preferences = preferences;
  static const _key = 'velora_cart_v1';
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<CartLine>> load() async {
    try {
      final raw = (await _prefs).getString(_key);
      if (raw == null) return const [];
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (item is Map) ?_tryParse(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  CartLine? _tryParse(Map<String, dynamic> json) {
    try {
      return CartLineJson.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static const _favoritesKey = 'velora_favorites_v1';

  Future<List<Product>> loadFavorites() async {
    try {
      final raw = (await _prefs).getString(_favoritesKey);
      if (raw == null) return const [];
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      final result = <Product>[];
      for (final item in list) {
        try {
          result.add(Product.fromJson(Map<String, dynamic>.from(item as Map)));
        } catch (_) {
          // Skip a corrupt entry and keep the rest.
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveFavorites(List<Product> products) async {
    try {
      await (await _prefs).setString(
        _favoritesKey,
        jsonEncode(products.map((p) => p.toJson()).toList()),
      );
    } catch (_) {
      // Best effort, like the cart.
    }
  }

  Future<void> save(List<CartLine> lines) async {
    try {
      await (await _prefs).setString(
        _key,
        jsonEncode(lines.map((l) => l.toJson()).toList()),
      );
    } catch (_) {
      // Persistence is best-effort; the in-memory cart keeps working.
    }
  }
}
