import 'package:flutter/material.dart';
import '../state/shop_state.dart';
import '../widgets/product_card.dart';

/// Read-only preview of the session cart. No order, payment, or quote requests.
class CheckoutPreviewScreen extends StatelessWidget {
  const CheckoutPreviewScreen({super.key, required this.shop});
  final ShopState shop;
  static const shippingMessage =
      'Shipping charges will be calculated when a shipping provider is connected.';
  static const paymentMessage =
      'Payment gateway integration is not available in this demo.';

  String _money(double amount, String? currency) =>
      '${currency == null ? '' : '$currency '}${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: shop,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Checkout preview', style: TextStyle(fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review your bag.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${shop.itemCount} ${shop.itemCount == 1 ? 'item' : 'items'} in your session bag',
                    style: const TextStyle(color: Color(0xFF94A3BF)),
                  ),
                  const SizedBox(height: 24),
                  if (shop.lines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFF85AAFF),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your bag is empty. Add a product to preview checkout.',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final items = Column(
                          children: [
                            for (final line in shop.lines) _line(line),
                          ],
                        );
                        final summary = _summary();
                        return constraints.maxWidth >= 760
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 6, child: items),
                                  const SizedBox(width: 26),
                                  Expanded(flex: 5, child: summary),
                                ],
                              )
                            : Column(
                                children: [
                                  items,
                                  const SizedBox(height: 12),
                                  summary,
                                ],
                              );
                      },
                    ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back to bag'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _line(CartLine line) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF111D34),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF20304B)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 72,
            height: 90,
            padding: const EdgeInsets.all(6),
            color: const Color(0xFF19253B),
            child: ProductImage(url: line.product.imageUrl),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.product.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (line.variation != null)
                Text(
                  line.variation!.name,
                  style: const TextStyle(color: Color(0xFF94A3BF)),
                ),
              const SizedBox(height: 8),
              Text(
                'Quantity: ${line.quantity}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3BF)),
              ),
              const SizedBox(height: 6),
              Text(
                '${_money(line.unitPrice, line.product.currency)} per item',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3BF)),
              ),
              const SizedBox(height: 6),
              Text(
                _money(line.subtotal, line.product.currency),
                style: const TextStyle(
                  color: Color(0xFF85AAFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _summary() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFF111D34),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF2B4168)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        for (final entry in shop.subtotals.entries)
          _amount('Subtotal', _money(entry.value, entry.key)),
        const Divider(height: 32, color: Color(0xFF2B4168)),
        const Text('Shipping', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          shippingMessage,
          style: TextStyle(color: Color(0xFFADB9D0), height: 1.5),
        ),
        const SizedBox(height: 20),
        for (final entry in shop.subtotals.entries)
          _amount(
            'Estimated total',
            _money(entry.value, entry.key),
            prominent: true,
          ),
        const SizedBox(height: 8),
        const Text(
          'Product subtotal only. Shipping is unknown and excluded; it is not free.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3BF), height: 1.5),
        ),
        if (shop.hasMixedCurrencies)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Different currencies are shown separately and are not combined.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3BF)),
            ),
          ),
        const Divider(height: 32, color: Color(0xFF2B4168)),
        const Icon(Icons.credit_card_off_outlined, color: Color(0xFF85AAFF)),
        const SizedBox(height: 10),
        const Text(paymentMessage, style: TextStyle(height: 1.5)),
        const SizedBox(height: 10),
        const Text(
          'This preview does not charge you, submit an order, reserve stock, or clear your bag. Cart and wishlist are kept in memory for this session only.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3BF), height: 1.5),
        ),
      ],
    ),
  );

  Widget _amount(String label, String value, {bool prominent = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 4,
          children: [
            Text(label, style: TextStyle(fontSize: prominent ? 16 : 13)),
            Text(
              value,
              style: TextStyle(
                fontSize: prominent ? 22 : 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF85AAFF),
              ),
            ),
          ],
        ),
      );
}
