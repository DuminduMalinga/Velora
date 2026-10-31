import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductApiException implements Exception {
  const ProductApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ProductApiService {
  ProductApiService({
    String baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://dummyjson.com',
    ),
    http.Client? client,
  }) : baseUri = Uri.parse(baseUrl),
       _client = client ?? http.Client();
  final Uri baseUri;
  final http.Client _client;
  void close() => _client.close();

  Future<dynamic> _get(
    List<String> path, [
    Map<String, String> query = const {},
  ]) async {
    if (!baseUri.hasAuthority || !['http', 'https'].contains(baseUri.scheme)) {
      throw const ProductApiException('Invalid API base URL');
    }
    final uri = baseUri.replace(
      pathSegments: [
        ...baseUri.pathSegments.where((s) => s.isNotEmpty),
        ...path,
      ],
      queryParameters: query.isEmpty ? null : query,
    );
    final response = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductApiException(
        'Product request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<ProductPage> getProducts({
    int limit = 20,
    int skip = 0,
    String? query,
    String? category,
    String? sortBy,
    String order = 'asc',
  }) async {
    if (limit < 0 || skip < 0 || !['asc', 'desc'].contains(order)) {
      throw ArgumentError('Invalid pagination or sort order');
    }
    final path = category != null
        ? ['products', 'category', category]
        : query?.trim().isNotEmpty == true
        ? ['products', 'search']
        : ['products'];
    final params = {
      'limit': '$limit',
      'skip': '$skip',
      if (query?.trim().isNotEmpty == true && category == null)
        'q': query!.trim(),
      'sortBy': ?sortBy,
      if (sortBy != null) 'order': order,
    };
    final json = await _get(path, params);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected product page');
    }
    return ProductPage.fromJson(json);
  }

  Future<Product?> getProduct(int id) async {
    if (id < 1) throw ArgumentError.value(id, 'id');
    try {
      final json = await _get(['products', '$id']);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Expected product');
      }
      return Product.fromJson(json);
    } on ProductApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<ProductCategory>> getCategories() async {
    final json = await _get(['products', 'categories']);
    if (json is! List) throw const FormatException('Expected categories');
    return List.unmodifiable(
      json.map(
        (c) => ProductCategory.fromJson(Map<String, dynamic>.from(c as Map)),
      ),
    );
  }
}
