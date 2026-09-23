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
    final id = json['id'] as String?;
    final productId = json['productId'] as String?;
    final storeName = json['storeName'] as String?;
    final originalPrice = _finiteDouble(json['originalPrice']);
    final offerPrice = _finiteDouble(json['offerPrice']);
    if (id == null ||
        id.trim().isEmpty ||
        productId == null ||
        productId.trim().isEmpty ||
        storeName == null ||
        storeName.trim().isEmpty ||
        originalPrice == null ||
        originalPrice <= 0 ||
        offerPrice == null ||
        offerPrice <= 0 ||
        offerPrice > originalPrice) {
      throw const FormatException('Ungültiges Angebot');
    }
    return Offer(
      id: id,
      productId: productId,
      storeName: storeName,
      originalPrice: originalPrice,
      offerPrice: offerPrice,
      validUntil: DateTime.parse(json['validUntil'] as String),
      buyQuantity: (json['buyQuantity'] as num?)?.toInt(),
      payQuantity: (json['payQuantity'] as num?)?.toInt(),
      coupon: json['coupon'] as bool? ?? false,
      couponPercent: _optionalFiniteDouble(json['couponPercent']),
      couponAmount: _optionalFiniteDouble(json['couponAmount']),
      cashback: json['cashback'] as bool? ?? false,
      cashbackPercent: _optionalFiniteDouble(json['cashbackPercent']),
      cashbackAmount: _optionalFiniteDouble(json['cashbackAmount']),
    );
  }

  static double? _finiteDouble(Object? value) =>
      value is num && value.toDouble().isFinite ? value.toDouble() : null;

  static double? _optionalFiniteDouble(Object? value) {
    if (value == null) return null;
    final parsed = _finiteDouble(value);
    if (parsed == null || parsed < 0) {
      throw const FormatException('Ungültiger Angebotsrabatt');
    }
    return parsed;
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
