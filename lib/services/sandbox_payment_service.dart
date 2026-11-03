import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import '../state/shop_state.dart';

enum DemoPaymentStatus { completed, failed, dismissed }

class DemoPaymentResult {
  const DemoPaymentResult(this.status, {this.paymentId, this.errorMessage});
  final DemoPaymentStatus status;
  final String? paymentId;
  final String? errorMessage;
}

class DemoPurchase {
  DemoPurchase(ShopState shop)
    : lines = List.unmodifiable(shop.lines),
      shipping = shop.shipping?.amount ?? 0,
      orderId =
          'VEL-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff).toRadixString(16)}';
  final List<CartLine> lines;
  final double shipping;
  final String orderId;
  double get total =>
      (lines.fold<int>(
            0,
            (n, l) => n + (l.unitPrice * 100).round() * l.quantity,
          ) +
          (shipping * 100).round()) /
      100;
}

/// Replace this boundary with a server-created checkout for production.
class SandboxPaymentService {
  static const merchantId = '1239081';
  static const secret = String.fromEnvironment('PAYHERE_MERCHANT_SECRET');
  static bool _active = false;

  /// Display diagnostics without logging credentials or customer details.
  static String safeError(String error, Iterable<String> customerValues) {
    var message = error;
    for (final value in [secret, ...customerValues]) {
      if (value.isEmpty) continue;
      message = message.replaceAll(value, '[redacted]');
      message = message.replaceAll(Uri.encodeComponent(value), '[redacted]');
    }
    message = message.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
    if (message.isEmpty) return 'PayHere returned an unspecified error.';
    return message.length > 400 ? '${message.substring(0, 400)}…' : message;
  }

  static Map<String, dynamic> paymentObject(
    DemoPurchase purchase,
    Map<String, String> customer,
  ) {
    if (purchase.lines.isEmpty ||
        !purchase.total.isFinite ||
        purchase.total <= 0 ||
        purchase.lines.any(
          (l) =>
              l.quantity < 1 ||
              !l.unitPrice.isFinite ||
              l.unitPrice < 0 ||
              (l.product.currency != null && l.product.currency != 'LKR'),
        )) {
      throw StateError(
        'Checkout requires a positive total and LKR demo prices.',
      );
    }
    return {
      ...customer,
      'sandbox': true,
      'merchant_id': merchantId,
      'merchant_secret': secret,
      // The native bridge requires this key. Empty means no endpoint; not a URL.
      'notify_url': '',
      'order_id': purchase.orderId,
      'items': purchase.lines
          .map((l) => '${l.product.title} x${l.quantity}')
          .join(', '),
      'amount': purchase.total.toStringAsFixed(2),
      'currency': 'LKR',
      for (var i = 0; i < purchase.lines.length; i++) ...{
        'item_number_${i + 1}':
            '${purchase.lines[i].productId}${purchase.lines[i].variation == null ? '' : '-${purchase.lines[i].variation!.id}'}',
        'item_name_${i + 1}':
            '${purchase.lines[i].product.title}${purchase.lines[i].variation == null ? '' : ' (${purchase.lines[i].variation!.name})'}',
        'quantity_${i + 1}': '${purchase.lines[i].quantity}',
        'amount_${i + 1}': purchase.lines[i].unitPrice.toStringAsFixed(2),
      },
    };
  }

  Future<DemoPaymentResult> pay(
    DemoPurchase purchase,
    Map<String, String> customer,
  ) async {
    if (_active) throw StateError('A payment is already in progress.');
    if (secret.trim().isEmpty) {
      throw StateError('Configure the local Sandbox Merchant Secret first.');
    }
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw StateError('PayHere requires an Android or iOS device.');
    }
    final payload = paymentObject(purchase, customer);
    _active = true;
    final result = Completer<DemoPaymentResult>();
    void finish(DemoPaymentResult value) {
      if (!result.isCompleted) result.complete(value);
    }

    try {
      PayHere.startPayment(
        payload,
        (id) => finish(
          DemoPaymentResult(
            DemoPaymentStatus.completed,
            paymentId: id.isEmpty ? null : id,
          ),
        ),
        (error) => finish(
          DemoPaymentResult(
            DemoPaymentStatus.failed,
            errorMessage: safeError(error, customer.values),
          ),
        ),
        () => finish(const DemoPaymentResult(DemoPaymentStatus.dismissed)),
      );
      return await result.future;
    } finally {
      _active = false;
    }
  }
}
