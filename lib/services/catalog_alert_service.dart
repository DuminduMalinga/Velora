import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import 'notification_service.dart';

/// Checks the full catalog independently of the user's search and filters.
class CatalogAlertService {
  CatalogAlertService({required this.repository, required this.notify});
  final ProductRepository repository;
  final Future<void> Function(AppAlert) notify;
  static const snapshotKey = 'catalog_alert_snapshot_v1';
  Timer? _timer;
  bool _active = false;
  bool _checking = false;
  int _generation = 0;

  Future<void> start() async {
    if (_active) return;
    _active = true;
    _timer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => unawaited(checkNow()),
    );
    await checkNow();
  }

  void stop() {
    _active = false;
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> checkNow() async {
    if (!_active || _checking) return;
    _checking = true;
    final generation = _generation;
    bool current() => _active && generation == _generation;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(snapshotKey);
      final previous = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      final products = <Product>[];
      var skip = 0;
      while (current()) {
        final page = await repository.getProducts(limit: 100, skip: skip);
        if (!current()) return;
        if (page.skip != skip || (page.hasMore && page.products.isEmpty)) {
          throw const FormatException('Incomplete catalog');
        }
        products.addAll(page.products);
        if (!page.hasMore) break;
        skip += page.products.length;
      }
      if (!current()) return;
      final arrivals = <Product>[];
      final discounts = <Product>[];
      final snapshot = Map<String, dynamic>.from(previous);
      for (final product in products) {
        final old = previous['${product.id}'] as Map<String, dynamic>?;
        final discount = product.discountPercentage ?? 0;
        if (raw != null && old == null) arrivals.add(product);
        if (discount > 0 &&
            product.inStock != false &&
            (old == null ||
                discount > (old['discount'] as num) ||
                product.effectivePrice < (old['price'] as num))) {
          discounts.add(product);
        }
        snapshot['${product.id}'] = {
          'discount': discount,
          'price': product.effectivePrice,
        };
      }
      if (discounts.isNotEmpty && current()) {
        final best = discounts.reduce(
          (a, b) => (a.discountPercentage ?? 0) >= (b.discountPercentage ?? 0)
              ? a
              : b,
        );
        await notify(
          AppAlert(
            type: AlertType.discount,
            title: 'Discounts to discover',
            body: discounts.length == 1
                ? '${best.title} is now ${best.discountPercentage}% off.'
                : '${discounts.length} products have offers to explore, with up to ${best.discountPercentage}% off.',
          ),
        );
      }
      if (arrivals.isNotEmpty && current()) {
        await notify(
          AppAlert(
            type: AlertType.newArrival,
            title: 'New arrivals at Velora',
            body: arrivals.length == 1
                ? '${arrivals.first.title} has joined the catalog.'
                : '${arrivals.length} new products have joined the catalog. Discover your next favorite.',
          ),
        );
      }
      if (current()) await prefs.setString(snapshotKey, jsonEncode(snapshot));
    } catch (error) {
      // Keep the previous snapshot so a failed request never invents arrivals.
      debugPrint('Catalog alert check failed: $error');
    } finally {
      _checking = false;
      if (_active && generation != _generation) unawaited(checkNow());
    }
  }
}
