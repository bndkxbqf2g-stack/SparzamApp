class MarketPrice {
  const MarketPrice({
    required this.productId,
    required this.storeName,
    required this.price,
    required this.updatedAt,
  });

  final String productId;
  final String storeName;
  final double price;
  final DateTime updatedAt;

  String get key => '$storeName|$productId';

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'storeName': storeName,
        'price': price,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MarketPrice.fromJson(Map<String, dynamic> json) => MarketPrice(
        productId: json['productId'] as String,
        storeName: json['storeName'] as String,
        price: (json['price'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
