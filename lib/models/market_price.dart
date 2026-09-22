enum MarketPriceSource { manual, openPrices }

class MarketPrice {
  const MarketPrice({
    required this.productId,
    required this.storeName,
    required this.price,
    required this.updatedAt,
    this.source = MarketPriceSource.manual,
    this.externalId,
    this.sourceLocationName,
  });

  final String productId;
  final String storeName;
  final double price;
  final DateTime updatedAt;
  final MarketPriceSource source;
  final int? externalId;
  final String? sourceLocationName;

  String get key => '$storeName|$productId';
  bool get isManual => source == MarketPriceSource.manual;

  bool isUsable({
    required DateTime now,
    required int openPricesMaxAgeDays,
  }) {
    if (isManual) return true;
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: openPricesMaxAgeDays));
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
    if (isManual) return 'manuell';
    return isUsable(
      now: now,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
    )
        ? 'aktuell'
        : 'veraltet';
  }

  String get sourceLabel => switch (source) {
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
      };

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String?;
    final matches =
        MarketPriceSource.values.where((item) => item.name == sourceName);

    return MarketPrice(
      productId: json['productId'] as String,
      storeName: json['storeName'] as String,
      price: (json['price'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      source: matches.isEmpty ? MarketPriceSource.manual : matches.first,
      externalId: (json['externalId'] as num?)?.toInt(),
      sourceLocationName: json['sourceLocationName'] as String?,
    );
  }
}
