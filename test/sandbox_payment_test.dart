import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/models/product.dart';
import 'package:velora/services/sandbox_payment_service.dart';
import 'package:velora/state/shop_state.dart';

void main() {
  test('Checkout allows actual positive totals below LKR 30', () {
    final shop = ShopState()
      ..add(
        const Product(
          id: 9,
          title: 'Small amount fixture',
          price: 8.94,
          stock: 1,
        ),
        null,
        1,
      );
    final payload = SandboxPaymentService.paymentObject(DemoPurchase(shop), {});
    expect(payload['amount'], '8.94');
    expect(payload['amount_1'], '8.94');
    shop.dispose();
  });
  test('Payment diagnostics redact credentials and customer values', () {
    final message = SandboxPaymentService.safeError(
      'Invalid customer fixture@example.com ${SandboxPaymentService.secret}',
      ['fixture@example.com'],
    );
    expect(message, isNot(contains('fixture@example.com')));
    if (SandboxPaymentService.secret.isNotEmpty) {
      expect(message, isNot(contains(SandboxPaymentService.secret)));
    }
    expect(message, contains('[redacted]'));
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('payhere_mobilesdk_flutter');
  const product = Product(
    id: 8,
    title: 'Test fixture',
    price: 12.34,
    stock: 10,
  );

  test(
    'Snapshot uses quantities and cents, includes quote, and has unique references',
    () {
      final shop = ShopState()..add(product, null, 3);
      shop.setShippingQuote(const ShippingQuote(amount: 1.25));
      final purchase = DemoPurchase(shop);
      final map = SandboxPaymentService.paymentObject(purchase, {
        'email': 'fixture@example.com',
      });
      expect(map['amount'], '38.27');
      expect(map['quantity_1'], '3');
      expect(map['amount_1'], '12.34');
      expect(map['currency'], 'LKR');
      expect(map['sandbox'], true);
      expect(map['notify_url'], isEmpty);
      expect(purchase.orderId, isNot(DemoPurchase(shop).orderId));
      shop.removeProduct(8);
      expect(purchase.lines.single.quantity, 3);
      shop.dispose();
    },
  );

  test('Cart locks during payment and clears only on completed result', () {
    final shop = ShopState()..add(product, null, 2);
    shop.beginPayment();
    expect(shop.add(product, null, 1), false);
    expect(shop.setQuantity(8, null, 1), false);
    shop.removeProduct(8);
    expect(shop.itemCount, 2);
    shop.endPayment();
    expect(shop.itemCount, 2);
    shop.beginPayment();
    shop.endPayment(completed: true);
    expect(shop.lines, isEmpty);
    shop.dispose();
  });

  for (final status in DemoPaymentStatus.values) {
    test(
      'Official bridge maps $status callback',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              expect(call.method, 'startPayment');
              return [
                {
                  'success': status == DemoPaymentStatus.completed,
                  'fldata': status == DemoPaymentStatus.completed
                      ? 'fixture-payment'
                      : 'fixture-error',
                  'flcallback': status == DemoPaymentStatus.dismissed
                      ? 'dismiss'
                      : 'error',
                },
              ];
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null),
        );
        final shop = ShopState()..add(product, null, 1);
        final service = SandboxPaymentService();
        final pending = service.pay(DemoPurchase(shop), {});
        await expectLater(
          service.pay(DemoPurchase(shop), {}),
          throwsStateError,
        );
        final result = await pending;
        expect(result.status, status);
        expect(
          result.paymentId,
          status == DemoPaymentStatus.completed ? 'fixture-payment' : null,
        );
        shop.dispose();
      },
      skip: SandboxPaymentService.secret.isEmpty
          ? 'Run with a non-secret test define; see docs.'
          : false,
    );
  }
}
