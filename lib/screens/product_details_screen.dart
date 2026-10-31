import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../state/shop_state.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.repository,
    required this.shop,
    this.onContinueShopping,
  });
  final int productId;
  final ProductRepository repository;
  final ShopState shop;
  final VoidCallback? onContinueShopping;
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  List<Product> _related = [];
  ProductVariation? _variation;
  bool _loading = true;
  Object? _error;
  Object? _relatedError;
  bool _relatedLoading = false;
  int _quantity = 1;
  int _image = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final product = await widget.repository.getProduct(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        _variation = null;
        _quantity = 1;
        _image = 0;
        _related = [];
        _relatedError = null;
        _loading = false;
        _relatedLoading = product?.category != null;
      });
      if (product != null) widget.shop.reconcile(product);
      if (product?.category != null) {
        try {
          final page = await widget.repository.getProducts(
            category: product!.category,
          );
          if (mounted) {
            setState(
              () => _related = page.products
                  .where((p) => p.id != product.id)
                  .toList(),
            );
          }
        } catch (error) {
          if (mounted) setState(() => _relatedError = error);
        } finally {
          if (mounted) setState(() => _relatedLoading = false);
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.shop,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Product details', style: TextStyle(fontSize: 17)),
        actions: [
          if (!_loading && _error == null && _product != null)
            IconButton(
              tooltip: widget.shop.favorites.contains(widget.productId)
                  ? 'Remove from wishlist'
                  : 'Add to wishlist',
              onPressed: () => widget.shop.toggleFavorite(
                widget.productId,
                product: _product,
              ),
              icon: Icon(
                widget.shop.favorites.contains(widget.productId)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: const Color(0xFF85AAFF),
              ),
            ),
          IconButton(
            tooltip: 'Open cart',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CartScreen(
                  shop: widget.shop,
                  repository: widget.repository,
                  onContinueShopping: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    widget.onContinueShopping?.call();
                  },
                  onProductTap: (product) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailsScreen(
                        productId: product.id,
                        repository: widget.repository,
                        shop: widget.shop,
                        onContinueShopping: widget.onContinueShopping,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            icon: Badge(
              isLabelVisible: widget.shop.itemCount > 0,
              label: Text('${widget.shop.itemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const _DetailsSkeleton()
          : _error != null
          ? _state(
              Icons.cloud_off_outlined,
              'Could not load this product',
              'Please try again to get the latest product information.',
              retry: true,
            )
          : _product == null
          ? _state(
              Icons.inventory_2_outlined,
              'Product unavailable',
              'This product is no longer in the collection.',
              retry: true,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth >= 720) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: _gallery(_product!),
                                    ),
                                    const SizedBox(width: 36),
                                    Expanded(
                                      flex: 5,
                                      child: _information(_product!),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _gallery(_product!),
                                  const SizedBox(height: 26),
                                  _information(_product!),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 36),
                          const Divider(color: Color(0xFF20304B)),
                          const SizedBox(height: 24),
                          const Text(
                            'More to discover',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Related products',
                            style: TextStyle(color: Color(0xFF94A3BF)),
                          ),
                          const SizedBox(height: 18),
                          if (_relatedLoading)
                            const SizedBox(
                              height: 150,
                              child: _DetailsSkeleton(imageOnly: true),
                            )
                          else if (_relatedError != null)
                            TextButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'Could not load related products. Retry',
                              ),
                            )
                          else if (_related.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No related products available.',
                                style: TextStyle(color: Color(0xFF94A3BF)),
                              ),
                            )
                          else
                            SizedBox(
                              height: 250,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _related.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final related = _related[index];
                                  return SizedBox(
                                    width: 180,
                                    child: Material(
                                      color: const Color(0xFF111D34),
                                      borderRadius: BorderRadius.circular(20),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                ProductDetailsScreen(
                                                  productId: related.id,
                                                  repository: widget.repository,
                                                  shop: widget.shop,
                                                  onContinueShopping:
                                                      widget.onContinueShopping,
                                                ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: _photo(
                                                  related.gallery.firstOrNull,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    related.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    related.formattedPrice,
                                                    style: const TextStyle(
                                                      color: Color(0xFF85AAFF),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _gallery(Product product) {
    final images = product.gallery;
    return Column(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF111D34),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF20304B)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: images.isEmpty
                ? _photo(null)
                : Stack(
                    children: [
                      PageView.builder(
                        key: ValueKey(product.id),
                        itemCount: images.length,
                        onPageChanged: (index) =>
                            setState(() => _image = index),
                        itemBuilder: (_, index) => Padding(
                          padding: const EdgeInsets.all(12),
                          child: _photo(images[index]),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xDD080F20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_image + 1} / ${images.length}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.all(3),
                  width: index == _image ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _image
                        ? const Color(0xFF4275FF)
                        : const Color(0xFF35425D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _information(Product product) {
    final selected = product.variations.isEmpty || _variation != null;
    final stock = product.availableStock(_variation);
    final remaining = widget.shop.remaining(product, _variation);
    final canAdd = selected && stock != null && remaining >= _quantity;
    final price = _variation?.price ?? product.effectivePrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.category != null)
          Text(
            product.category!,
            style: const TextStyle(
              color: Color(0xFF85AAFF),
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
        const SizedBox(height: 10),
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          product.formatPrice(price),
          style: const TextStyle(
            fontSize: 28,
            color: Color(0xFF85AAFF),
            fontWeight: FontWeight.w700,
          ),
        ),
        if ((product.discountPercentage ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 10,
              children: [
                Text(
                  product.formatPrice(product.price),
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Color(0xFF94A3BF),
                  ),
                ),
                Text(
                  '${product.discountPercentage}% off',
                  style: const TextStyle(color: Color(0xFF85AAFF)),
                ),
              ],
            ),
          ),
        if (product.brand != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              product.brand!,
              style: const TextStyle(color: Color(0xFF94A3BF)),
            ),
          ),
        if (product.rating != null || product.reviews.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 7,
              children: [
                if (product.rating != null) ...[
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFCC75),
                    size: 20,
                  ),
                  Text('${product.rating}'),
                ],
                Text(
                  '(${product.reviewCount} reviews)',
                  style: const TextStyle(color: Color(0xFF94A3BF)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF14243D),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            !selected
                ? 'Select a variation to check availability'
                : stock == null
                ? (product.inStock == true
                      ? 'In stock - quantity unconfirmed'
                      : 'Stock availability not provided')
                : stock == 0
                ? 'Out of stock'
                : '${product.availabilityStatus ?? 'Available'} - $stock in stock',
            style: const TextStyle(color: Color(0xFFACC7FF), fontSize: 12),
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'About this product',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          product.description?.trim().isNotEmpty == true
              ? product.description!
              : 'No description available.',
          style: const TextStyle(height: 1.7, color: Color(0xFFADB9D0)),
        ),
        if (product.reviews.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Customer reviews',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          for (final review in product.reviews)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      if (review.reviewerName != null)
                        Text(
                          review.reviewerName!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      if (review.rating != null)
                        Text(
                          '${review.rating} ★',
                          style: const TextStyle(color: Color(0xFFFFCC75)),
                        ),
                    ],
                  ),
                  if (review.comment != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        review.comment!,
                        style: const TextStyle(
                          color: Color(0xFFADB9D0),
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
        if (product.variations.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Choose your variation',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.variations
                .map(
                  (variation) => ChoiceChip(
                    label: Text(variation.name),
                    selected: _variation == variation,
                    onSelected: (_) => setState(() {
                      _variation = variation;
                      _quantity = 1;
                    }),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 26),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            const Text(
              'Quantity',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF35425D)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Decrease quantity',
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Semantics(
                    liveRegion: true,
                    label: 'Quantity $_quantity',
                    child: Text(
                      '$_quantity',
                      key: const ValueKey('quantity'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Increase quantity',
                    onPressed: selected && _quantity < remaining
                        ? () => setState(() => _quantity++)
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: canAdd
                ? () {
                    final added = widget.shop.add(
                      product,
                      _variation,
                      _quantity,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added
                              ? 'Added to your bag'
                              : 'The requested quantity is unavailable.',
                        ),
                      ),
                    );
                    setState(() => _quantity = 1);
                  }
                : null,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(
              !selected
                  ? 'Select a variation'
                  : stock == null
                  ? 'Availability unconfirmed'
                  : remaining == 0
                  ? (stock == 0
                        ? 'Out of stock'
                        : 'Available quantity is in your bag')
                  : 'Add to Cart',
            ),
          ),
        ),
      ],
    );
  }

  Widget _photo(String? url) => url == null
      ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 38,
                color: Color(0xFF8392AE),
              ),
              SizedBox(height: 8),
              Text(
                'No image available',
                style: TextStyle(color: Color(0xFF94A3BF)),
              ),
            ],
          ),
        )
      : Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const _DetailsSkeleton(imageOnly: true),
          errorBuilder: (_, error, stack) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 38,
              semanticLabel: 'Image unavailable',
            ),
          ),
        );
  Widget _state(
    IconData icon,
    String title,
    String subtitle, {
    bool retry = false,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: const Color(0xFF85AAFF)),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3BF)),
          ),
          if (retry) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton({this.imageOnly = false});
  final bool imageOnly;
  @override
  Widget build(BuildContext context) {
    Widget block(double height) => Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF20304B),
        borderRadius: BorderRadius.circular(20),
      ),
    );
    return Semantics(
      label: 'Loading product',
      child: imageOnly
          ? block(double.infinity)
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(aspectRatio: 1, child: block(double.infinity)),
                    const SizedBox(height: 24),
                    block(32),
                    const SizedBox(height: 12),
                    block(24),
                    const SizedBox(height: 26),
                    block(100),
                  ],
                ),
              ),
            ),
    );
  }
}
