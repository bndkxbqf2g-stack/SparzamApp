import 'dart:convert';
import 'price_observation.dart';

class Offer {
  const Offer({
    required this.id,
    required this.productId,
    required this.storeName,
    required this.originalPrice,
    this.originalPriceVerified = true,
    this.evidenceConfidence,
    required this.offerPrice,
    required this.validUntil,
    this.validFrom,
    this.source = 'manual',
    this.sourceAdapter,
    this.capturedAt,
    this.proofRef,
    this.imageUrl,
    this.packageAmount,
    this.packageUnit,
    this.unitPrice,
    this.locationId,
    this.region,
    this.address,
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
  final bool originalPriceVerified;
  /// Provenance confidence for the stored evidence. Null preserves legacy
  /// offers that predate the confidence field.
  final EvidenceConfidence? evidenceConfidence;
  final double offerPrice;
  final DateTime validUntil;
  final DateTime? validFrom;
  final String source;
  /// Optional adapter identity kept separate from the legal/source class.
  /// For example, a KaufDA discovery record still has
  /// `source == retailerWebsite`, while this field preserves the adapter
  /// that produced the evidence.
  final String? sourceAdapter;
  /// Timestamp supplied by the adapter when this offer was captured. It is
  /// optional for legacy/manual offers and is evidence metadata only; validity
  /// still comes from [validFrom]/[validUntil].
  final DateTime? capturedAt;
  final String? proofRef;
  final String? imageUrl;
  /// Source-provided package basis. This is kept separate from the requested
  /// purchase quantity and is copied into price observations when available.
  final double? packageAmount;
  final String? packageUnit;
  /// Normalized price for the package basis, for example €/kg or €/l.
  final double? unitPrice;
  final String? locationId;
  final String? region;
  final String? address;
  final int? buyQuantity;
  final int? payQuantity;
  final bool coupon;
  final double? couponPercent;
  final double? couponAmount;
  final bool cashback;
  final double? cashbackPercent;
  final double? cashbackAmount;

  /// Invalid legacy/imported counts are treated as a normal offer so a
  /// malformed rule can never make a route price artificially free.
  bool get hasMultiBuy => buyQuantity != null &&
      payQuantity != null &&
      buyQuantity! > 0 &&
      payQuantity! > 0 &&
      payQuantity! < buyQuantity!;
  bool get hasCoupon => coupon || couponPercent != null || couponAmount != null;
  bool get hasCashback => cashback || cashbackPercent != null || cashbackAmount != null;

  factory Offer.fromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    final id = json['id'] as String?;
    final productId = json['productId'] as String?;
    final storeName = json['storeName'] as String?;
    final originalPrice = _finiteDouble(json['originalPrice']);
    final originalPriceVerified = json['originalPriceVerified'] as bool? ?? true;
    final evidenceConfidence = parseEvidenceConfidence(json['evidenceConfidence']);
    final offerPrice = _finiteDouble(json['offerPrice']);
    final packageAmount = _optionalPositiveDouble(json['packageAmount']);
    final packageUnit = json['packageUnit'] as String?;
    final unitPrice = _optionalPositiveDouble(json['unitPrice']);
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
        (originalPriceVerified && offerPrice > originalPrice) ||
        (packageAmount != null && packageUnit?.trim().isNotEmpty != true)) {
      throw const FormatException('Ungültiges Angebot');
    }
    return Offer(
      id: id,
      productId: productId,
      storeName: storeName,
      originalPrice: originalPrice,
      originalPriceVerified: originalPriceVerified,
      evidenceConfidence: evidenceConfidence,
      offerPrice: offerPrice,
      validUntil: DateTime.parse(json['validUntil'] as String),
      validFrom: DateTime.tryParse(json['validFrom'] as String? ?? ''),
      source: json['source'] as String? ?? 'manual',
      sourceAdapter: json['sourceAdapter'] as String?,
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? ''),
      proofRef: json['proofRef'] as String?,
      imageUrl: json['imageUrl'] as String?,
      packageAmount: packageAmount,
      packageUnit: packageUnit,
      unitPrice: unitPrice,
      locationId: json['locationId'] as String?,
      region: json['region'] as String?,
      address: json['address'] as String?,
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

  static double? _optionalPositiveDouble(Object? value) {
    if (value == null) return null;
    final parsed = _finiteDouble(value);
    if (parsed == null || parsed <= 0) {
      throw const FormatException('Ungültige Angebotsmenge');
    }
    return parsed;
  }

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
        'originalPriceVerified': originalPriceVerified,
        'evidenceConfidence': evidenceConfidence?.name,
        'offerPrice': offerPrice,
        'validUntil': validUntil.toIso8601String(),
        'validFrom': validFrom?.toIso8601String(),
        'source': source,
        'sourceAdapter': sourceAdapter,
        'capturedAt': capturedAt?.toIso8601String(),
        'proofRef': proofRef,
        'imageUrl': imageUrl,
        'packageAmount': packageAmount,
        'packageUnit': packageUnit,
        'unitPrice': unitPrice,
        'locationId': locationId,
        'region': region,
        'address': address,
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

