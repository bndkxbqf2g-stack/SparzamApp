enum PriceObservationSource {
  receipt,
  manual,
  openPrices,
  retailer,
  retailerWebsite,
  leaflet,
  shelfImage,
  shelfVideo,
  community,
  estimate,
}

enum PriceObservationKind { regular, offer, unknown }

/// One recorded claim about a price. Identity and price evidence stay separate.
class PriceObservation {
  const PriceObservation({
    required this.id,
    required this.storeName,
    required this.price,
    required this.observedAt,
    required this.source,
    this.productId,
    this.familyKey,
    this.variant,
    this.ean,
    this.locationId,
    this.region,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.kind = PriceObservationKind.unknown,
    this.validFrom,
    this.validUntil,
    this.identityConfidence = 1,
    this.proofRef,
    this.discounted = false,
  });

  final String id;
  final String? productId;
  final String? familyKey;
  final String? variant;
  final String? ean;
  final String storeName;
  final String? locationId;
  final String? region;
  final double price;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final PriceObservationKind kind;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime observedAt;
  final PriceObservationSource source;
  /// Confidence in product identity only; source and age are scored separately.
  final double identityConfidence;
  final String? proofRef;
  final bool discounted;

  bool get isValid => id.isNotEmpty &&
      (productId?.isNotEmpty == true || familyKey?.isNotEmpty == true) &&
      storeName.isNotEmpty && price.isFinite && price > 0 &&
      (quantity == null || quantity!.isFinite && quantity! > 0) &&
      (unitPrice == null || unitPrice!.isFinite && unitPrice! > 0) &&
      identityConfidence.isFinite &&
      identityConfidence >= 0 && identityConfidence <= 1 &&
      (validFrom == null || validUntil == null ||
          !validUntil!.isBefore(validFrom!));

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'familyKey': familyKey,
        'variant': variant,
        'ean': ean,
        'storeName': storeName,
        'locationId': locationId,
        'region': region,
        'price': price,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'kind': kind.name,
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'observedAt': observedAt.toIso8601String(),
        'source': source.name,
        'identityConfidence': identityConfidence,
        'proofRef': proofRef,
        'discounted': discounted,
      };

  factory PriceObservation.fromJson(Map<String, dynamic> json) {
    final source = PriceObservationSource.values.byName(json['source'] as String);
    final kindName = json['kind'] as String?;
    final observation = PriceObservation(
      id: json['id'] as String,
      productId: json['productId'] as String?,
      familyKey: json['familyKey'] as String?,
      variant: json['variant'] as String?,
      ean: json['ean'] as String?,
      storeName: json['storeName'] as String,
      locationId: json['locationId'] as String?,
      region: json['region'] as String?,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      kind: kindName == null
          ? PriceObservationKind.unknown
          : PriceObservationKind.values.byName(kindName),
      validFrom: DateTime.tryParse(json['validFrom'] as String? ?? ''),
      validUntil: DateTime.tryParse(json['validUntil'] as String? ?? ''),
      observedAt: DateTime.parse(json['observedAt'] as String),
      source: source,
      identityConfidence:
          (json['identityConfidence'] as num?)?.toDouble() ?? 1,
      proofRef: json['proofRef'] as String?,
      discounted: json['discounted'] as bool? ?? false,
    );
    if (!observation.isValid) throw const FormatException('Ungültige Preisbeobachtung');
    return observation;
  }
}
