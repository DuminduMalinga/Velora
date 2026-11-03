import 'package:flutter/material.dart';
import '../services/sandbox_payment_service.dart';
import '../widgets/product_card.dart';

class SandboxPaymentResultScreen extends StatelessWidget {
  const SandboxPaymentResultScreen({
    super.key,
    required this.purchase,
    required this.result,
    required this.onContinueShopping,
  });
  final DemoPurchase purchase;
  final DemoPaymentResult result;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final completed = result.status == DemoPaymentStatus.completed;
    final dismissed = result.status == DemoPaymentStatus.dismissed;
    return Scaffold(
      appBar: AppBar(title: const Text('Sandbox Demo Payment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle_outline
                        : dismissed
                        ? Icons.cancel_outlined
                        : Icons.error_outline,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    completed
                        ? 'Sandbox Demo Payment Completed'
                        : dismissed
                        ? 'Sandbox Demo Payment Canceled'
                        : 'Sandbox Demo Payment Failed',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    completed
                        ? 'PayHere reported completion. This is a Sandbox test, not a real transaction. No real order was created and payment has not been verified by a server.'
                        : 'Your bag has been kept. ${dismissed ? 'Payment was dismissed.' : 'PayHere reported an error. Check your connection and Sandbox settings before retrying.'}',
                  ),
                  const SizedBox(height: 20),
                  if (!completed &&
                      !dismissed &&
                      result.errorMessage != null) ...[
                    Text(
                      'PayHere error',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(result.errorMessage!),
                    const SizedBox(height: 20),
                  ],
                  SelectableText('Order reference: ${purchase.orderId}'),
                  if (result.paymentId != null)
                    SelectableText('Payment ID: ${result.paymentId}'),
                  const Divider(height: 32),
                  for (final line in purchase.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: ProductImage(url: line.product.imageUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${line.product.title}${line.variation == null ? '' : ' • ${line.variation!.name}'}\nQuantity: ${line.quantity} × LKR ${line.unitPrice.toStringAsFixed(2)}\nLKR ${line.subtotal.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    'Shipping included: LKR ${purchase.shipping.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sandbox total: LKR ${purchase.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  if (!completed)
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to checkout'),
                    ),
                  OutlinedButton(
                    onPressed: onContinueShopping,
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
