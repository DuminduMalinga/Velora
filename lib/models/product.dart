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
    if (id == null || name is! String) {
      throw const FormatException('Invalid variation');
    }
    return ProductVariation(
      id: '$id',
      name: name,
      price: ProductModel.readPrice(json['price']),
      stock: ProductModel.readCount(json['stock']),
    );
  }
}

class ProductReview {
  const ProductReview({
    this.rating,
    this.comment,
    this.date,
    this.reviewerName,
    this.reviewerEmail,
  });
  final double? rating;
  final String? comment;
  final DateTime? date;
  final String? reviewerName;
  final String? reviewerEmail;
  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    rating: ProductModel.readPrice(json['rating']),
    comment: ProductModel.readString(json['comment']),
    date: DateTime.tryParse('${json['date']}'),
    reviewerName: ProductModel.readString(json['reviewerName']),
    reviewerEmail: ProductModel.readString(json['reviewerEmail']),
  );
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.description,
    this.discountPercentage,
    this.rating,
    this.stock,
    this.brand,
    this.category,
    this.thumbnail,
    this.images = const [],
    this.availabilityStatus,
    this.reviews = const [],
    this.currency,
    this.variations = const [],
  });
  final int id;
  final String title;
  final String? description;
  final double price;
  final double? discountPercentage;
  final double? rating;
  final int? stock;
  final String? brand;
  final String? category;
  final String? thumbnail;
  final List<String> images;
  final String? availabilityStatus;
  final List<ProductReview> reviews;
  final String? currency;
  final List<ProductVariation> variations;

  // Compatibility getters keep existing premium widgets reusable.
  String get name => title;
  String? get imageUrl => thumbnail ?? images.firstOrNull;
  int get reviewCount => reviews.length;
  bool? get inStock => stock == null ? null : stock! > 0;
  List<String> get gallery => {...images, ?thumbnail}.toList();
  double get effectivePrice =>
      (price * (1 - (discountPercentage ?? 0) / 100) * 100).round() / 100;
  String formatPrice(double value) =>
      '${currency == null ? '' : '$currency '}${value.toStringAsFixed(2)}';
  String get formattedPrice => formatPrice(effectivePrice);
  int? availableStock(ProductVariation? variation) {
    if (stock == 0) return 0;
    if (variations.isNotEmpty &&
        (variation == null || variation.stock == null)) {
      return null;
    }
    final other = variation?.stock;
    if (stock == null) return other;
    if (other == null) return stock;
    return stock! < other ? stock : other;
  }

  static String? readString(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value : null;
  static double? readPrice(dynamic value) {
    if (value == null) return null;
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null || !number.isFinite || number < 0) {
      throw const FormatException('Invalid numeric product field');
    }
    return number;
  }

  static int? readCount(dynamic value) {
    final number = readPrice(value);
    if (number == null) return null;
    if (number != number.truncateToDouble()) {
      throw const FormatException('Invalid integer field');
    }
    return number.toInt();
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = readCount(json['id']);
    final title = readString(json['title']);
    final price = readPrice(json['price']);
    final discount = readPrice(json['discountPercentage']);
    if (id == null ||
        id < 1 ||
        title == null ||
        price == null ||
        (discount != null && discount > 100)) {
      throw const FormatException('Invalid product response');
    }
    final rawImages = json['images'];
    final rawReviews = json['reviews'];
    final rawVariants = json['variations'];
    return ProductModel(
      id: id,
      title: title,
      price: price,
      description: readString(json['description']),
      discountPercentage: discount,
      rating: readPrice(json['rating']),
      stock: readCount(json['stock']),
      brand: readString(json['brand']),
      category: readString(json['category']),
      thumbnail: readString(json['thumbnail']),
      images: rawImages is List
          ? List.unmodifiable(
              rawImages.whereType<String>().where((s) => s.trim().isNotEmpty),
            )
          : const [],
      availabilityStatus: readString(json['availabilityStatus']),
      reviews: rawReviews is List
          ? List.unmodifiable(
              rawReviews.whereType<Map>().map(
                (r) => ProductReview.fromJson(Map<String, dynamic>.from(r)),
              ),
            )
          : const [],
      currency: readString(json['currency']),
      // DummyJSON has no standard variants. Only parse explicitly supplied real variants.
      variations: rawVariants is List
          ? List.unmodifiable(
              rawVariants.whereType<Map>().map(
                (v) => ProductVariation.fromJson(Map<String, dynamic>.from(v)),
              ),
            )
          : const [],
    );
  }
}

typedef Product = ProductModel;

class ProductCategory {
  const ProductCategory({required this.slug, required this.name});
  final String slug;
  final String name;
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final slug = Product.readString(json['slug']);
    final name = Product.readString(json['name']);
    if (slug == null || name == null) {
      throw const FormatException('Invalid category');
    }
    return ProductCategory(slug: slug, name: name);
  }
}

class ProductPage {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;
  bool get hasMore => skip + products.length < total;
  factory ProductPage.fromJson(Map<String, dynamic> json) {
    final items = json['products'];
    final total = Product.readCount(json['total']);
    final skip = Product.readCount(json['skip']);
    final limit = Product.readCount(json['limit']);
    if (items is! List || total == null || skip == null || limit == null) {
      throw const FormatException('Invalid catalog response');
    }
    return ProductPage(
      products: List.unmodifiable(
        items.map((p) => Product.fromJson(Map<String, dynamic>.from(p as Map))),
      ),
      total: total,
      skip: skip,
      limit: limit,
    );
  }
}
