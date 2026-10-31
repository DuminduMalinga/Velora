import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.url, this.fit = BoxFit.contain});
  final String? url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => url == null
      ? const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF8392AE),
            semanticLabel: 'No image available',
          ),
        )
      : Image.network(
          url!,
          fit: fit,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          errorBuilder: (_, error, stack) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Color(0xFF8392AE),
              semanticLabel: 'Image unavailable',
            ),
          ),
        );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });
  final Product product;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF111D34),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(19),
      side: const BorderSide(color: Color(0xFF20304B)),
    ),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFF19253B),
                  padding: const EdgeInsets.all(8),
                  child: ProductImage(url: product.imageUrl),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton.filledTonal(
                    tooltip: favorite
                        ? 'Remove from wishlist'
                        : 'Add to wishlist',
                    onPressed: onFavorite,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xDD0D172B),
                    ),
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: const Color(0xFF85AAFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.category != null)
                  Text(
                    product.category!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3BF),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.formattedPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF85AAFF),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        tooltip: 'View product options',
                        padding: EdgeInsets.zero,
                        onPressed: onTap,
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                      ),
                    ),
                  ],
                ),
                if ((product.discountPercentage ?? 0) > 0)
                  Text(
                    '${product.formatPrice(product.price)}  -${product.discountPercentage}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3BF),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
