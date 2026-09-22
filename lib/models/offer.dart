import 'dart:convert';

class Offer {
  const Offer({
    required this.id,
    required this.productId,
    required this.storeName,
    required this.originalPrice,
    required this.offerPrice,
    required this.validUntil,
    this.buyQuantity,
    this.payQuantity,
    this.coupon = false,
    this.couponPercent,
    this.couponAmount,
    this.cashback = false,
    this.cashbackPercent,
    this.cashbackAmount,
  });

  final String id;
  final String productId;
  final String storeName;
  final double originalPrice;
  final double offerPrice;
  final DateTime validUntil;
  final int? buyQuantity;
  final int? payQuantity;
  final bool coupon;
  final double? couponPercent;
  final double? couponAmount;
  final bool cashback;
  final double? cashbackPercent;
  final double? cashbackAmount;

  bool get hasMultiBuy => buyQuantity != null && payQuantity != null;
  bool get hasCoupon => coupon || couponPercent != null || couponAmount != null;
  bool get hasCashback => cashback || cashbackPercent != null || cashbackAmount != null;

  factory Offer.fromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return Offer(
      id: json['id'] as String,
      productId: json['productId'] as String,
      storeName: json['storeName'] as String,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      offerPrice: (json['offerPrice'] as num).toDouble(),
      validUntil: DateTime.parse(json['validUntil'] as String),
      buyQuantity: (json['buyQuantity'] as num?)?.toInt(),
      payQuantity: (json['payQuantity'] as num?)?.toInt(),
      coupon: json['coupon'] as bool? ?? false,
      couponPercent: (json['couponPercent'] as num?)?.toDouble(),
      couponAmount: (json['couponAmount'] as num?)?.toDouble(),
      cashback: json['cashback'] as bool? ?? false,
      cashbackPercent: (json['cashbackPercent'] as num?)?.toDouble(),
      cashbackAmount: (json['cashbackAmount'] as num?)?.toDouble(),
    );
  }

  String toJson() => jsonEncode({
        'id': id,
        'productId': productId,
        'storeName': storeName,
        'originalPrice': originalPrice,
        'offerPrice': offerPrice,
        'validUntil': validUntil.toIso8601String(),
        'buyQuantity': buyQuantity,
        'payQuantity': payQuantity,
        'coupon': coupon,
        'couponPercent': couponPercent,
        'couponAmount': couponAmount,
        'cashback': cashback,
        'cashbackPercent': cashbackPercent,
        'cashbackAmount': cashbackAmount,
      });
}
