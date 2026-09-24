class ReceiptPriceStat {
  const ReceiptPriceStat({
    required this.familyKey,
    required this.storeName,
    required this.latestPrice,
    required this.latestAt,
    required this.observationCount,
    required this.medianPrice,
    required this.comparable,
    required this.priceBasis,
  });

  final String familyKey;
  final String storeName;
  final double latestPrice;
  final DateTime latestAt;
  final int observationCount;
  final double medianPrice;
  final bool comparable;
  final String priceBasis;
}
