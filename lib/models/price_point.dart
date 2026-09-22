import 'dart:convert';

class PricePoint {
  const PricePoint({
    required this.productId,
    required this.storeName,
    required this.price,
    required this.date,
  });

  final String productId;
  final String storeName;
  final double price;
  final DateTime date;

  factory PricePoint.fromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return PricePoint(
      productId: json['productId'] as String,
      storeName: json['storeName'] as String,
      price: (json['price'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  String toJson() => jsonEncode({
        'productId': productId,
        'storeName': storeName,
        'price': price,
        'date': date.toIso8601String(),
      });
}
