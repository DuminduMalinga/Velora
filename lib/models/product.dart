class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.category,
    this.currency,
    this.featured = false,
  });

  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? category;
  final String? currency;
  final bool featured;

  String get formattedPrice =>
      '${currency == null ? '' : '$currency '}${price.toStringAsFixed(2)}';

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'] ?? json['title'];
    final price = num.tryParse('${json['price']}');
    if (id == null ||
        name is! String ||
        name.trim().isEmpty ||
        price == null ||
        !price.isFinite ||
        price < 0) {
      throw const FormatException('Invalid product response');
    }
    final category = json['category'];
    final images = json['images'];
    final image =
        json['imageUrl'] ??
        json['image'] ??
        (images is List && images.isNotEmpty ? images.first : null);
    return Product(
      id: '$id',
      name: name,
      price: price.toDouble(),
      imageUrl: image is String ? image : null,
      category: category is String
          ? category
          : category is Map
          ? category['name'] as String?
          : null,
      currency: json['currency'] as String?,
      featured: json['featured'] == true || json['isFeatured'] == true,
    );
  }
}
