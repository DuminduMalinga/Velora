import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> fetchProducts();
}

class ApiNotConfigured implements Exception {
  const ApiNotConfigured();
}

class ApiProductRepository implements ProductRepository {
  ApiProductRepository({
    this.endpoint = const String.fromEnvironment('PRODUCTS_API_URL'),
  });
  final String endpoint;

  @override
  Future<List<Product>> fetchProducts() async {
    if (endpoint.trim().isEmpty) throw const ApiNotConfigured();
    final uri = Uri.parse(endpoint);
    if (!uri.hasAuthority || !['http', 'https'].contains(uri.scheme)) {
      throw const FormatException('Invalid API endpoint');
    }
    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Product request failed (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final items = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['products'] ?? decoded['data']
        : null;
    if (items is! List) throw const FormatException('Expected a product list');
    return items
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
