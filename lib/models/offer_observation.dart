/// Normalized offer evidence shared by retailer adapters.
///
/// Nullable price and validity fields mean "unknown". They must never be
/// converted to 0 or treated as routeable without a current validity period.
class OfferObservation {
  const OfferObservation({
    required this.market,
    this.exactStore,
    required this.productFamily,
    this.variant,
    this.packageSize,
    this.regularPrice,
    this.offerPrice,
    this.unitPrice,
    this.validFrom,
    this.validUntil,
    required this.source,
    required this.capturedAt,
  });

  final String market;
  final String? exactStore;
  final String productFamily;
  final String? variant;
  final String? packageSize;
  final double? regularPrice;
  final double? offerPrice;
  final double? unitPrice;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String source;
  final DateTime capturedAt;

  bool isCurrentAt(DateTime now) {
    final price = offerPrice;
    if (price == null || !price.isFinite || price <= 0) return false;
    final start = validFrom;
    final end = validUntil;
    if (start == null || end == null || end.isBefore(start)) return false;
    return !now.isBefore(start) && !now.isAfter(end);
  }

  Map<String, dynamic> toJson() => {
        'market': market,
        'exactStore': exactStore,
        'productFamily': productFamily,
        'variant': variant,
        'packageSize': packageSize,
        'regularPrice': regularPrice,
        'offerPrice': offerPrice,
        'unitPrice': unitPrice,
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'source': source,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory OfferObservation.fromJson(Map<String, dynamic> json) =>
      OfferObservation(
        market: json['market'] as String? ?? '',
        exactStore: json['exactStore'] as String?,
        productFamily: json['productFamily'] as String? ?? '',
        variant: json['variant'] as String?,
        packageSize: json['packageSize'] as String?,
        regularPrice: _double(json['regularPrice']),
        offerPrice: _double(json['offerPrice']),
        unitPrice: _double(json['unitPrice']),
        validFrom: DateTime.tryParse(json['validFrom'] as String? ?? ''),
        validUntil: DateTime.tryParse(json['validUntil'] as String? ?? ''),
        source: json['source'] as String? ?? 'unknown',
        capturedAt: DateTime.tryParse(
              json['capturedAt'] as String? ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  static double? _double(Object? value) =>
      value is num && value.toDouble().isFinite ? value.toDouble() : null;
}
