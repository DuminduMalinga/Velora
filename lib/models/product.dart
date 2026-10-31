class ProductVariation {
  const ProductVariation({
    required this.id,
    required this.name,
    this.price,
    this.stock,
  });
  final String id;
  final String name;
  final double? price;
  final int? stock;

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'] ?? json['label'];
    if (id == null || name is! String || name.trim().isEmpty) {
      throw const FormatException('Invalid variation');
    }
    return ProductVariation(
      id: '$id',
      name: name,
      price: Product.readPrice(json['price']),
      stock: Product.readCount(json['stock'] ?? json['availableQuantity']),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.images = const [],
    this.category,
    this.currency,
    this.featured = false,
    this.description,
    this.rating,
    this.reviewCount,
    this.stock,
    this.inStock,
    this.variations = const [],
  });

  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final List<String> images;
  final String? category;
  final String? currency;
  final bool featured;
  final String? description;
  final double? rating;
  final int? reviewCount;
  final int? stock;
  final bool? inStock;
  final List<ProductVariation> variations;

  List<String> get gallery => {...images, ?imageUrl}.toList();
  String formatPrice(double value) =>
      '${currency == null ? '' : '$currency '}${value.toStringAsFixed(2)}';
  String get formattedPrice => formatPrice(price);

  int? availableStock(ProductVariation? variation) {
    if (inStock == false || stock == 0) return 0;
    if (variations.isNotEmpty &&
        (variation == null || variation.stock == null)) {
      return null;
    }
    final variantStock = variation?.stock;
    if (stock == null) return variantStock;
    if (variantStock == null) return stock;
    return stock! < variantStock ? stock : variantStock;
  }

  static double? readPrice(dynamic value) {
    if (value == null) return null;
    final number = num.tryParse('$value');
    if (number == null || !number.isFinite || number < 0) {
      throw const FormatException('Invalid numeric product field');
    }
    return number.toDouble();
  }

  static int? readCount(dynamic value) {
    final number = readPrice(value);
    if (number == null) return null;
    if (number != number.truncateToDouble()) {
      throw const FormatException('Invalid quantity');
    }
    return number.toInt();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'] ?? json['title'];
    final price = readPrice(json['price']);
    if (id == null || name is! String || name.trim().isEmpty || price == null) {
      throw const FormatException('Invalid product response');
    }
    final category = json['category'];
    final image = json['imageUrl'] ?? json['image'];
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.whereType<String>().where((s) => s.isNotEmpty).toList()
        : <String>[];
    final rawRating = json['rating'];
    final rating = rawRating is Map
        ? rawRating['rate'] ?? rawRating['average']
        : rawRating;
    final rawVariations = json['variations'] ?? json['variants'];
    return Product(
      id: '$id',
      name: name,
      price: price,
      imageUrl: image is String ? image : images.firstOrNull,
      images: List.unmodifiable(images),
      category: category is String
          ? category
          : category is Map
          ? category['name'] as String?
          : null,
      currency: json['currency'] as String?,
      featured: json['featured'] == true || json['isFeatured'] == true,
      description: json['description'] as String?,
      rating: readPrice(rating),
      reviewCount: readCount(
        json['reviewCount'] ?? (rawRating is Map ? rawRating['count'] : null),
      ),
      stock: readCount(json['stock'] ?? json['availableQuantity']),
      inStock: json['inStock'] as bool?,
      variations: rawVariations is List
          ? List.unmodifiable(
              rawVariations.map(
                (v) => ProductVariation.fromJson(
                  Map<String, dynamic>.from(v as Map),
                ),
              ),
            )
          : const [],
    );
  }
}
