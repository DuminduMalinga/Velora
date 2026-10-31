import '../theme/app_theme.dart';
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
        title: Text('Checkout preview', style: TextStyle(fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review your bag.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${shop.itemCount} ${shop.itemCount == 1 ? 'item' : 'items'} in your session bag',
                    style: TextStyle(color: context.adaptive(0xFF94A3BF)),
                  ),
                  SizedBox(height: 24),
                  if (shop.lines.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: context.adaptive(0xFF85AAFF),
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
                            for (final line in shop.lines) _line(context, line),
                          ],
                        );
                        final summary = _summary(context);
                        return constraints.maxWidth >= 760
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 6, child: items),
                                  SizedBox(width: 26),
                                  Expanded(flex: 5, child: summary),
                                ],
                              )
                            : Column(
                                children: [
                                  items,
                                  SizedBox(height: 12),
                                  summary,
                                ],
                              );
                      },
                    ),
                  SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, size: 18),
                    label: Text('Back to bag'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _line(BuildContext context, CartLine line) => Container(
    margin: EdgeInsets.only(bottom: 14),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.adaptive(0xFF111D34),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.adaptive(0xFF20304B)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 72,
            height: 90,
            padding: EdgeInsets.all(6),
            color: context.adaptive(0xFF19253B),
            child: ProductImage(url: line.product.imageUrl),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.product.title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (line.variation != null)
                Text(
                  line.variation!.name,
                  style: TextStyle(color: context.adaptive(0xFF94A3BF)),
                ),
              SizedBox(height: 8),
              Text(
                'Quantity: ${line.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.adaptive(0xFF94A3BF),
                ),
              ),
              SizedBox(height: 6),
              Text(
                '${_money(line.unitPrice, line.product.currency)} per item',
                style: TextStyle(
                  fontSize: 12,
                  color: context.adaptive(0xFF94A3BF),
                ),
              ),
              SizedBox(height: 6),
              Text(
                _money(line.subtotal, line.product.currency),
                style: TextStyle(
                  color: context.adaptive(0xFF85AAFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _summary(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: context.adaptive(0xFF111D34),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.adaptive(0xFF2B4168)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 20),
        for (final entry in shop.subtotals.entries)
          _amount(context, 'Subtotal', _money(entry.value, entry.key)),
        Divider(height: 32, color: context.adaptive(0xFF2B4168)),
        Text('Shipping', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Text(
          shippingMessage,
          style: TextStyle(color: context.adaptive(0xFFADB9D0), height: 1.5),
        ),
        SizedBox(height: 20),
        for (final entry in shop.subtotals.entries)
          _amount(
            context,
            'Estimated total',
            _money(entry.value, entry.key),
            prominent: true,
          ),
        SizedBox(height: 8),
        Text(
          'Product subtotal only. Shipping is unknown and excluded; it is not free.',
          style: TextStyle(
            fontSize: 12,
            color: context.adaptive(0xFF94A3BF),
            height: 1.5,
          ),
        ),
        if (shop.hasMixedCurrencies)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Different currencies are shown separately and are not combined.',
              style: TextStyle(
                fontSize: 12,
                color: context.adaptive(0xFF94A3BF),
              ),
            ),
          ),
        Divider(height: 32, color: context.adaptive(0xFF2B4168)),
        Icon(
          Icons.credit_card_off_outlined,
          color: context.adaptive(0xFF85AAFF),
        ),
        SizedBox(height: 10),
        Text(paymentMessage, style: TextStyle(height: 1.5)),
        SizedBox(height: 10),
        Text(
          'This preview does not charge you, submit an order, reserve stock, or clear your bag. Cart and wishlist are kept in memory for this session only.',
          style: TextStyle(
            fontSize: 12,
            color: context.adaptive(0xFF94A3BF),
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _amount(
    BuildContext context,
    String label,
    String value, {
    bool prominent = false,
  }) => Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
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
            color: context.adaptive(0xFF85AAFF),
          ),
        ),
      ],
    ),
  );
}
