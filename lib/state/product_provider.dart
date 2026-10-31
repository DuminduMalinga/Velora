import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(this.repository);
  final ProductRepository repository;
  List<Product> products = [];
  List<ProductCategory> categories = [];
  Object? error;
  Object? categoriesError;
  Object? moreError;
  bool loading = true;
  bool loadingMore = false;
  bool categoriesLoading = true;
  bool hasMore = false;
  int total = 0;
  int _skip = 0;
  int _generation = 0;
  bool _disposed = false;
  String query = '';
  String? category;
  int sort = 0;
  double? maxPrice;
  Timer? _debounce;

  Future<void> initialize() async => Future.wait([loadCategories(), refresh()]);
  Future<void> loadCategories() async {
    categoriesLoading = true;
    categoriesError = null;
    _notify();
    try {
      final result = await repository.getCategories();
      if (!_disposed) categories = result;
    } catch (e) {
      if (!_disposed) categoriesError = e;
    } finally {
      if (!_disposed) {
        categoriesLoading = false;
        _notify();
      }
    }
  }

  void search(String value) {
    query = value;
    _debounce?.cancel();
    // Invalidate in-flight requests immediately, even during the debounce window.
    _generation++;
    loading = true;
    error = null;
    _notify();
    _debounce = Timer(const Duration(milliseconds: 350), refresh);
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    final generation = ++_generation;
    loading = true;
    loadingMore = false;
    error = null;
    moreError = null;
    _notify();
    try {
      final page = await _request(0);
      if (_disposed || generation != _generation) return;
      products = page.products;
      total = page.total;
      _skip = page.skip + page.products.length;
      hasMore = page.hasMore && page.products.isNotEmpty;
    } catch (e) {
      if (!_disposed && generation == _generation) error = e;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  Future<ProductPage> _request(int skip) => repository.getProducts(
    // DummyJSON has no combined category+search or max-price query. Fetch that
    // result set completely before applying those particular local filters.
    limit: (maxPrice != null || (category != null && query.trim().isNotEmpty))
        ? 0
        : 20,
    skip: skip,
    query: query,
    category: category,
    sortBy: switch (sort) {
      1 || 2 => 'price',
      3 => 'title',
      _ => null,
    },
    order: sort == 2 ? 'desc' : 'asc',
  );

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final generation = _generation;
    loadingMore = true;
    moreError = null;
    _notify();
    try {
      final page = await _request(_skip);
      if (_disposed || generation != _generation) return;
      products = {
        for (final p in [...products, ...page.products]) p.id: p,
      }.values.toList();
      _skip = page.skip + page.products.length;
      total = page.total;
      hasMore = page.hasMore && page.products.isNotEmpty;
    } catch (e) {
      if (!_disposed && generation == _generation) moreError = e;
    } finally {
      if (!_disposed && generation == _generation) {
        loadingMore = false;
        _notify();
      }
    }
  }

  List<Product> get visible => products
      .where(
        (p) =>
            (maxPrice == null || p.effectivePrice <= maxPrice!) &&
            (category == null ||
                query.trim().isEmpty ||
                '${p.title} ${p.description ?? ''}'.toLowerCase().contains(
                  query.trim().toLowerCase(),
                )),
      )
      .toList();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }
}
