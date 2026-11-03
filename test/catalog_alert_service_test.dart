import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/data/product_repository.dart';
import 'package:velora/models/product.dart';
import 'package:velora/services/catalog_alert_service.dart';
import 'package:velora/services/notification_service.dart';

class CatalogRepository extends ProductRepository {
  List<Product> items = [];
  bool fail = false;
  Completer<void>? hold;
  final skips = <int>[];

  @override
  Future<ProductPage> getProducts({
    int limit = 20,
    int skip = 0,
    String? query,
    String? category,
    String? sortBy,
    String order = 'asc',
  }) async {
    skips.add(skip);
    await hold?.future;
    if (fail) throw Exception('Offline');
    // Small pages exercise complete pagination even when the requested limit is higher.
    return ProductPage(
      products: items.skip(skip).take(2).toList(),
      total: items.length,
      skip: skip,
      limit: 2,
    );
  }

  @override
  Future<Product?> getProduct(int id) async => null;
  @override
  Future<List<ProductCategory>> getCategories() async => [];
}

Product product(int id, {double discount = 0, double price = 100}) => Product(
  id: id,
  title: 'Product $id',
  price: price,
  discountPercentage: discount,
  stock: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Initial offers, full-catalog arrivals, price drops and deduplication',
    () async {
      final repository = CatalogRepository()
        ..items = [product(1, discount: 10), product(2), product(3)];
      final alerts = <AppAlert>[];
      final monitor = CatalogAlertService(
        repository: repository,
        notify: (alert) async => alerts.add(alert),
      );
      addTearDown(monitor.stop);
      await monitor.start();
      expect(repository.skips, [0, 2]);
      expect(alerts.map((a) => a.type), [AlertType.discount]);
      await monitor.checkNow();
      expect(alerts.length, 1);
      repository.items = [
        product(1, discount: 20),
        product(2),
        product(3),
        product(4),
      ];
      await monitor.checkNow();
      expect(alerts.map((a) => a.type), [
        AlertType.discount,
        AlertType.discount,
        AlertType.newArrival,
      ]);
      expect(alerts.last.body, contains('Product 4'));
      await monitor.checkNow();
      expect(alerts.length, 3);
      repository.items = [
        product(1, discount: 20, price: 90),
        product(2),
        product(3),
        product(4),
      ];
      await monitor.checkNow();
      expect(alerts.last.type, AlertType.discount);
      expect(alerts.length, 4);
      monitor.stop();
      final restarted = CatalogAlertService(
        repository: repository,
        notify: (alert) async => alerts.add(alert),
      );
      addTearDown(restarted.stop);
      await restarted.start();
      expect(alerts.length, 4);
    },
  );

  test(
    'Failed checks preserve baseline and stopped checks deliver nothing',
    () async {
      final repository = CatalogRepository()..items = [product(1)];
      final alerts = <AppAlert>[];
      final monitor = CatalogAlertService(
        repository: repository,
        notify: (alert) async => alerts.add(alert),
      );
      addTearDown(monitor.stop);
      await monitor.start();
      repository.fail = true;
      repository.items.add(product(2));
      await monitor.checkNow();
      expect(alerts, isEmpty);
      repository.fail = false;
      await monitor.checkNow();
      expect(alerts.single.type, AlertType.newArrival);
      repository.hold = Completer<void>();
      final pending = monitor.checkNow();
      monitor.stop();
      repository.items.add(product(3, discount: 50));
      repository.hold!.complete();
      await pending;
      expect(alerts.length, 1);
      final requestCount = repository.skips.length;
      await monitor.checkNow();
      expect(repository.skips.length, requestCount);
    },
  );
}
