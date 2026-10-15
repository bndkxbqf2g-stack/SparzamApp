import 'price_observation.dart';

enum MarketPriceSource { receipt, manual, openPrices, prospect }

class MarketPrice {
  const MarketPrice({
    required this.productId,
    required this.storeName,
    required this.price,
    required this.updatedAt,
    this.source = MarketPriceSource.manual,
    this.externalId,
    this.sourceLocationName,
    this.sourceLocationId,
    this.sourceAdapter,
    this.discounted = false,
    this.proofRef,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.identityConfidence = 1,
    this.kind = PriceObservationKind.unknown,
    this.evidenceConfidence,
  });

  final String productId;
  final String storeName;
  final double price;
  final DateTime updatedAt;
  final MarketPriceSource source;
  final int? externalId;
  final String? sourceLocationName;
  /// Stable source location/branch ID when the provider exposes one.
  final String? sourceLocationId;
  /// Optional concrete adapter identity retained when this price is projected
  /// from a PriceObservation.
  final String? sourceAdapter;
  final bool discounted;

  /// Evidence metadata retained when a price is projected from the central
  /// observation database. Legacy market prices may leave these fields null.
  final String? proofRef;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
  final double identityConfidence;
  final PriceObservationKind kind;
  /// Evidence confidence survives projection from the central observation store.
  final EvidenceConfidence? evidenceConfidence;

  String get key => '$storeName|$productId';
  bool get isManual =>
      source == MarketPriceSource.manual || source == MarketPriceSource.receipt;

  bool get hasComparableBasis =>
      (quantity == null ||
          (quantity!.isFinite && quantity! > 0)) &&
      (unitPrice == null ||
          (unitPrice!.isFinite && unitPrice! > 0)) &&
      (quantity == null || unit?.trim().isNotEmpty == true);

  bool isUsable({
    required DateTime now,
    required int openPricesMaxAgeDays,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final observed = DateTime(
      updatedAt.year,
      updatedAt.month,
      updatedAt.day,
    );
    // A future timestamp is invalid evidence for every source. Manual prices
    // are allowed to stay usable indefinitely, but they still cannot describe
    // a price that has not been observed yet.
    if (observed.isAfter(today) ||
        evidenceConfidence == EvidenceConfidence.probable ||
        evidenceConfidence == EvidenceConfidence.uncertain ||
        !identityConfidence.isFinite ||
        identityConfidence < 1 ||
        !hasComparableBasis) {
      return false;
    }
    if (source == MarketPriceSource.manual) return true;
    // External regular prospect prices are bounded by the same configurable
    // freshness window as other external observations.
    final maxAgeDays = switch (source) {
      MarketPriceSource.receipt => 30,
      MarketPriceSource.prospect || MarketPriceSource.openPrices =>
        openPricesMaxAgeDays,
      MarketPriceSource.manual => null,
    };
    if (maxAgeDays == null) return true;
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: maxAgeDays));
    return !observed.isBefore(cutoff);
  }

  String freshnessLabel({
    required DateTime now,
    required int openPricesMaxAgeDays,
  }) {
    if (source == MarketPriceSource.manual) return 'manuell';
    if (source == MarketPriceSource.receipt) {
      return isUsable(now: now, openPricesMaxAgeDays: openPricesMaxAgeDays)
          ? 'Bonpreis' : 'historischer Bonpreis';
    }
    if (source == MarketPriceSource.prospect) {
      return isUsable(now: now, openPricesMaxAgeDays: openPricesMaxAgeDays)
          ? 'Prospektpreis' : 'historischer Prospektpreis';
    }
    return isUsable(
      now: now,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
    )
        ? 'aktuell'
        : 'veraltet';
  }

  String get sourceLabel {
    if (sourceAdapter?.trim().toLowerCase() == 'kaufda') return 'KaufDA';
    return switch (source) {
      MarketPriceSource.receipt => 'Kassenbon',
      MarketPriceSource.manual => 'Eigener Preis',
      MarketPriceSource.openPrices => 'Open Prices',
      MarketPriceSource.prospect => 'Prospekt',
    };
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'storeName': storeName,
        'price': price,
        'updatedAt': updatedAt.toIso8601String(),
        'source': source.name,
        'externalId': externalId,
        'sourceLocationName': sourceLocationName,
        'sourceLocationId': sourceLocationId,
        'sourceAdapter': sourceAdapter,
        'discounted': discounted,
        'proofRef': proofRef,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'identityConfidence': identityConfidence,
        'kind': kind.name,
        'evidenceConfidence': evidenceConfidence?.name,
      };

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'] as String?;
    final storeName = json['storeName'] as String?;
    final price = (json['price'] as num?)?.toDouble();
    if (productId == null || productId.trim().isEmpty ||
        storeName == null || storeName.trim().isEmpty ||
        price == null || !price.isFinite || price <= 0) {
      throw const FormatException('Ungültiger Marktpreis');
    }
    final sourceName = json['source'] as String?;
    final matches =
        MarketPriceSource.values.where((item) => item.name == sourceName);
    final kindName = json['kind'] as String?;
    final identityConfidence =
        (json['identityConfidence'] as num?)?.toDouble() ?? 1;
    if (!identityConfidence.isFinite ||
        identityConfidence < 0 ||
        identityConfidence > 1) {
      throw const FormatException('Ungültige Preisidentität');
    }

    return MarketPrice(
      productId: productId,
      storeName: storeName,
      price: price,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      source: matches.isEmpty ? MarketPriceSource.manual : matches.first,
      externalId: (json['externalId'] as num?)?.toInt(),
      sourceLocationName: json['sourceLocationName'] as String?,
      sourceLocationId: json['sourceLocationId'] as String?,
      sourceAdapter: json['sourceAdapter'] as String?,
      discounted: json['discounted'] as bool? ?? false,
      proofRef: json['proofRef'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      identityConfidence: identityConfidence,
      kind: kindName == null
          ? PriceObservationKind.unknown
          : PriceObservationKind.values.byName(kindName),
      evidenceConfidence: parseEvidenceConfidence(json['evidenceConfidence']),
    );
  }
}
