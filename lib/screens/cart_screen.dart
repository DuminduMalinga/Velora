import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/shop_state.dart';
import '../data/product_repository.dart';

/// Shared by the Home cart tab and standalone routes from product details.
class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.shop,
    required this.onContinueShopping,
    this.onProductTap,
    this.onCheckout,
    this.embedded = false,
    this.repository,
  });
  final ShopState shop;
  final VoidCallback onContinueShopping;
  final ValueChanged<Product>? onProductTap;
  final Future<void> Function()? onCheckout;
  final bool embedded;
  final ProductRepository? repository;

  String _money(double amount, String? currency) =>
      '${currency == null ? '' : '$currency '}${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: shop,
    builder: (context, _) {
      final content = shop.lines.isEmpty
          ? _empty(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR NEXT FAVORITES',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF85AAFF),
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your shopping bag.',
                        style: TextStyle(
                          fontSize: 32,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${shop.itemCount} ${shop.itemCount == 1 ? 'item' : 'items'} chosen by you',
                        style: const TextStyle(color: Color(0xFF94A3BF)),
                      ),
                      const SizedBox(height: 28),
                      if (repository != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextButton.icon(
                            onPressed: () async {
                              try {
                                await shop.refreshCart(repository!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Prices and available quantities updated.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not refresh your bag. Your current items are still shown.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh prices & stock'),
                          ),
                        ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final items = Column(
                            children: [
                              for (final line in shop.lines)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _item(context, line),
                                ),
                            ],
                          );
                          if (constraints.maxWidth >= 780) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: items),
                                const SizedBox(width: 28),
                                Expanded(flex: 4, child: _summary(context)),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              items,
                              const SizedBox(height: 10),
                              _summary(context),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
      return embedded
          ? content
          : Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Shopping bag',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              body: SafeArea(child: content),
            );
    },
  );

  Widget _item(BuildContext context, CartLine line) {
    final product = line.product;
    final variantId = line.variation?.id;
    final canIncrease = shop.remaining(product, line.variation) > 0;
    final image = product.gallery.firstOrNull;
    return Container(
      key: ValueKey((product.id, variantId)),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111D34),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF20304B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: onProductTap != null,
                label: 'View ${product.name}',
                child: InkWell(
                  onTap: onProductTap == null
                      ? null
                      : () => onProductTap!(product),
                  borderRadius: BorderRadius.circular(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 84,
                      height: 100,
                      color: const Color(0xFF19253B),
                      child: image == null
                          ? const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFF8392AE),
                              semanticLabel: 'No image available',
                            )
                          : Image.network(
                              image,
                              fit: BoxFit.contain,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                              errorBuilder: (_, error, stack) => const Icon(
                                Icons.broken_image_outlined,
                                semanticLabel: 'Image unavailable',
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (line.variation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          line.variation!.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3BF),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      _money(line.unitPrice, product.currency),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF85AAFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'per item',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3BF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1528),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFF293953)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Decrease quantity of ${product.name}',
                      onPressed: line.quantity <= 1
                          ? null
                          : () => shop.setQuantity(
                              product.id,
                              variantId,
                              line.quantity - 1,
                            ),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    SizedBox(
                      width: 28,
                      child: Semantics(
                        liveRegion: true,
                        label: 'Quantity: ${line.quantity}',
                        child: Text(
                          '${line.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Increase quantity of ${product.name}',
                      onPressed: canIncrease
                          ? () => shop.setQuantity(
                              product.id,
                              variantId,
                              line.quantity + 1,
                            )
                          : null,
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => shop.removeLine(product.id, variantId),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFAAB8D1),
                ),
              ),
            ],
          ),
          if (!canIncrease)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Available quantity reached',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3BF)),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Item total',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3BF)),
                ),
              ),
              Flexible(
                child: Text(
                  _money(line.subtotal, product.currency),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final currency = shop.subtotals.keys.firstOrNull;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF152542), Color(0xFF101B30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2B4168)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF85AAFF),
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Order summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          for (final entry in shop.subtotals.entries)
            _amount('Subtotal', _money(entry.value, entry.key)),
          const SizedBox(height: 16),
          _amount(
            'Shipping',
            shop.shipping == null
                ? 'Not yet quoted'
                : _money(shop.shipping!.amount, shop.shipping!.currency),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(color: Color(0xFF2B4168)),
          ),
          if (!shop.hasMixedCurrencies)
            _amount(
              shop.shipping == null ? 'Estimated total' : 'Total',
              _money(shop.total!, currency),
              prominent: true,
            )
          else ...[
            for (final entry in shop.subtotals.entries)
              _amount(
                'Estimated total',
                _money(entry.value, entry.key),
                prominent: true,
              ),
          ],
          const SizedBox(height: 12),
          Text(
            shop.hasMixedCurrencies
                ? 'Your bag contains different currencies. These amounts cannot be combined into one order.'
                : shop.shipping == null
                ? 'Shipping is not included until a delivery quote is available.'
                : 'Includes your current delivery quote.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF94A3BF),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: shop.hasMixedCurrencies
                  ? null
                  : () => _checkout(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Checkout'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onContinueShopping,
              child: const Text('Continue Shopping'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amount(String label, String value, {bool prominent = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: prominent ? 16 : 13,
                  color: prominent ? Colors.white : const Color(0xFFADB9D0),
                  fontWeight: prominent ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: prominent ? 22 : 14,
                  color: prominent ? const Color(0xFF85AAFF) : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _checkout(BuildContext context) async {
    if (onCheckout != null) {
      try {
        await onCheckout!();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checkout could not be opened. Please try again.'),
            ),
          );
        }
      }
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: Color(0xFF85AAFF),
              ),
              const SizedBox(height: 18),
              const Text(
                'Checkout is not available yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your bag is ready. Ordering and payment are not available yet. Your items will stay in your bag during this session.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3BF), height: 1.6),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to bag'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 210,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 174,
                        height: 174,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0xFF203F88), Color(0xFF0E1A32)],
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: -.12,
                        child: Container(
                          width: 110,
                          height: 122,
                          decoration: BoxDecoration(
                            color: const Color(0xFF162E5D),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFF4275FF)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x334275FF),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 66,
                            color: Color(0xFF9FBEFF),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 18,
                        right: 12,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 26,
                          color: Color(0xFF85AAFF),
                        ),
                      ),
                      const Positioned(
                        bottom: 22,
                        left: 10,
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: Color(0xFF4275FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your bag is a blank canvas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Make room for your next favorite.\nDiscover something you’ll love.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3BF), height: 1.7),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: onContinueShopping,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 17,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Continue Shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
