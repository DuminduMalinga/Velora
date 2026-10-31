import '../models/product.dart';
import 'product_api_service.dart';

abstract class ProductRepository {
  Future<ProductPage> getProducts({
    int limit = 20,
    int skip = 0,
    String? query,
    String? category,
    String? sortBy,
    String order = 'asc',
  });
  Future<Product?> getProduct(int id);
  Future<List<ProductCategory>> getCategories();
  Future<List<Product>> fetchProducts() async => (await getProducts()).products;
  void dispose() {}
}

class ApiProductRepository extends ProductRepository {
  ApiProductRepository({ProductApiService? service})
    : service = service ?? ProductApiService();
  final ProductApiService service;
  @override
  Future<ProductPage> getProducts({
    int limit = 20,
    int skip = 0,
    String? query,
    String? category,
    String? sortBy,
    String order = 'asc',
  }) => service.getProducts(
    limit: limit,
    skip: skip,
    query: query,
    category: category,
    sortBy: sortBy,
    order: order,
  );
  @override
  Future<Product?> getProduct(int id) => service.getProduct(id);
  @override
  Future<List<ProductCategory>> getCategories() => service.getCategories();
  @override
  void dispose() => service.close();
}
