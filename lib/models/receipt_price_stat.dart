class ReceiptPriceStat {
  const ReceiptPriceStat({
    required this.familyKey,
    this.productId,
    required this.storeName,
    required this.latestPrice,
    required this.latestAt,
    required this.observationCount,
    required this.medianPrice,
    required this.comparable,
    required this.priceBasis,
    this.identityConfirmed = true,
  });

  final String familyKey;
  final String? productId;
  final String storeName;
  final double latestPrice;
  final DateTime latestAt;
  final int observationCount;
  final double medianPrice;
  final bool comparable;
  final String priceBasis;

  /// True only when a concrete product assignment behind this statistic was
  /// explicitly confirmed. Family-only observations remain usable for a
  /// generic family request.
  final bool identityConfirmed;
}
