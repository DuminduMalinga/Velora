import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:velora/data/product_api_service.dart';
import 'package:velora/data/product_repository.dart';
import 'package:velora/models/product.dart';
import 'package:velora/state/product_provider.dart';

const live = bool.fromEnvironment('RUN_LIVE_API_TESTS');

void main() {
  test(
    'Real DummyJSON endpoints, field parsing, images, pagination and sorting',
    () async {
      final service = ProductApiService();
      addTearDown(service.close);
      // Every product and expected field below is obtained from a live response.
      final response = await http.get(Uri.https('dummyjson.com', '/products'));
      expect(response.statusCode, 200);
      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      final page = ProductPage.fromJson(raw);
      expect(page.products, isNotEmpty);
      final firstJson = (raw['products'] as List).first as Map<String, dynamic>;
      final first = page.products.first;
      expect(first.id, firstJson['id']);
      expect(first.title, firstJson['title']);
      expect(first.description, firstJson['description']);
      expect(first.price, (firstJson['price'] as num).toDouble());
      expect(
        first.discountPercentage,
        (firstJson['discountPercentage'] as num).toDouble(),
      );
      expect(first.stock, firstJson['stock']);
      expect(first.rating, (firstJson['rating'] as num).toDouble());
      expect(first.brand, firstJson['brand']);
      expect(first.category, firstJson['category']);
      expect(first.thumbnail, firstJson['thumbnail']);
      expect(first.images, firstJson['images']);
      expect(first.availabilityStatus, firstJson['availabilityStatus']);
      final reviews = firstJson['reviews'] as List;
      expect(first.reviews.length, reviews.length);
      if (reviews.isNotEmpty) {
        expect(first.reviews.first.comment, reviews.first['comment']);
        expect(first.reviews.first.reviewerName, reviews.first['reviewerName']);
        expect(first.reviews.first.rating, reviews.first['rating']);
      }
      expect(first.variations, isEmpty);
      expect(
        first.effectivePrice,
        (first.price * (1 - first.discountPercentage! / 100) * 100).round() /
            100,
      );
      final detail = await service.getProduct(first.id);
      expect(detail!.id, first.id);
      final limited = await service.getProducts(limit: 20, skip: 0);
      final next = await service.getProducts(
        limit: 20,
        skip: limited.products.length,
      );
      expect(limited.products.length, 20);
      expect(next.skip, limited.products.length);
      expect(
        limited.products
            .map((p) => p.id)
            .toSet()
            .intersection(next.products.map((p) => p.id).toSet()),
        isEmpty,
      );
      final query = first.title.split(' ').first;
      final search = await service.getProducts(query: query, limit: 0);
      expect(search.products.map((p) => p.id), contains(first.id));
      final categories = await service.getCategories();
      expect(categories, isNotEmpty);
      final category = categories.firstWhere((c) => c.slug == first.category);
      final categorized = await service.getProducts(category: category.slug);
      expect(categorized.products, isNotEmpty);
      expect(
        categorized.products.every((p) => p.category == category.slug),
        isTrue,
      );
      final ascending = await service.getProducts(
        sortBy: 'price',
        order: 'asc',
      );
      expect(ascending.products, isNotEmpty);
      for (var i = 1; i < ascending.products.length; i++) {
        expect(
          ascending.products[i].price >= ascending.products[i - 1].price,
          isTrue,
        );
      }
      final descending = await service.getProducts(
        sortBy: 'price',
        order: 'desc',
      );
      expect(
        descending.products.first.price >= ascending.products.first.price,
        isTrue,
      );
      for (final url in {first.thumbnail!, first.images.first}) {
        final image = await http.get(Uri.parse(url));
        expect(image.statusCode, 200);
        expect(image.headers['content-type'], startsWith('image/'));
        expect(image.bodyBytes, isNotEmpty);
      }
      final all = await service.getProducts(limit: 0);
      final highestId = all.products
          .map((p) => p.id)
          .reduce((a, b) => a > b ? a : b);
      expect(await service.getProduct(highestId + 1), isNull);
      // Parse every live record, including products with omitted optional fields.
      expect(all.products.length, all.total);
      expect(all.products.every((p) => p.effectivePrice >= 0), isTrue);
    },
    skip: !live,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'Live catalog provider loads, searches, categories and paginates',
    () async {
      final repository = ApiProductRepository();
      final provider = ProductProvider(repository);
      addTearDown(repository.dispose);
      addTearDown(provider.dispose);
      await provider.initialize();
      expect(provider.error, isNull);
      expect(provider.categoriesError, isNull);
      expect(provider.products.length, 20);
      final first = provider.products.first;
      await provider.loadMore();
      expect(provider.products.length, greaterThan(20));
      provider.query = first.title;
      await provider.refresh();
      expect(provider.visible.map((p) => p.id), contains(first.id));
      provider.query = '';
      provider.category = first.category;
      provider.maxPrice = first.effectivePrice;
      await provider.refresh();
      expect(
        provider.visible.every(
          (p) =>
              p.category == first.category &&
              p.effectivePrice <= first.effectivePrice,
        ),
        isTrue,
      );
      expect(provider.hasMore, isFalse);
    },
    skip: !live,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
