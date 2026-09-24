enum MarketPriceSource { receipt, manual, openPrices }

class MarketPrice {
  const MarketPrice({
    required this.productId,
    required this.storeName,
    required this.price,
    required this.updatedAt,
    this.source = MarketPriceSource.manual,
    this.externalId,
    this.sourceLocationName,
    this.discounted = false,
  });

  final String productId;
  final String storeName;
  final double price;
  final DateTime updatedAt;
  final MarketPriceSource source;
  final int? externalId;
  final String? sourceLocationName;
  final bool discounted;

  String get key => '$storeName|$productId';
  bool get isManual =>
      source == MarketPriceSource.manual || source == MarketPriceSource.receipt;

  bool isUsable({
    required DateTime now,
    required int openPricesMaxAgeDays,
  }) {
    if (source == MarketPriceSource.manual) return true;
    // Provisional safety window until receipt price stability is measured.
    final maxAgeDays = source == MarketPriceSource.receipt
        ? 30 : openPricesMaxAgeDays;
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: maxAgeDays));
    final observed = DateTime(
      updatedAt.year,
      updatedAt.month,
      updatedAt.day,
    );
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
    return isUsable(
      now: now,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
    )
        ? 'aktuell'
        : 'veraltet';
  }

  String get sourceLabel => switch (source) {
        MarketPriceSource.receipt => 'Kassenbon',
        MarketPriceSource.manual => 'Eigener Preis',
        MarketPriceSource.openPrices => 'Open Prices',
      };

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'storeName': storeName,
        'price': price,
        'updatedAt': updatedAt.toIso8601String(),
        'source': source.name,
        'externalId': externalId,
        'sourceLocationName': sourceLocationName,
        'discounted': discounted,
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

    return MarketPrice(
      productId: productId,
      storeName: storeName,
      price: price,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      source: matches.isEmpty ? MarketPriceSource.manual : matches.first,
      externalId: (json['externalId'] as num?)?.toInt(),
      sourceLocationName: json['sourceLocationName'] as String?,
      discounted: json['discounted'] as bool? ?? false,
    );
  }
}
