import '../../models/list_item.dart';

/// A list position with no comparable price evidence in one or more markets.
///
/// The ordering deliberately uses only facts that are already known for the
/// list and the enabled markets. It never uses a fallback or estimated price.
class PriceGapPriority {
  const PriceGapPriority({
    required this.item,
    required this.missingMarketCount,
    required this.marketCount,
    this.purchaseCount = 0,
    this.historicalPriceLevel,
  });

  final ListItem item;
  final int missingMarketCount;
  final int marketCount;
  final int purchaseCount;
  final double? historicalPriceLevel;

  int get knownMarketCount =>
      (marketCount - missingMarketCount).clamp(0, marketCount).toInt();

  /// A deterministic prioritization index for unresolved price evidence.
  ///
  /// This is deliberately not an amount of money and never becomes a route
  /// price. It combines only signals that are already known for this list
  /// position: the share of markets without evidence, requested quantity,
  /// confirmed purchase frequency and an exact historical median when one is
  /// available. A neutral factor of one keeps positions without history
  /// comparable without inventing a price.
  double get dataGapScore {
    if (missingMarketCount <= 0) return 0;
    final coverage = marketCount <= 0
        ? 1.0
        : missingMarketCount / marketCount;
    final quantity = item.quantity > 0 ? item.quantity.toDouble() : 1.0;
    final purchaseFrequency = purchaseCount > 0
        ? purchaseCount.toDouble()
        : 1.0;
    final historicalBasis = historicalPriceLevel ?? 1.0;
    return coverage * quantity * purchaseFrequency * historicalBasis;
  }

  String get marketLabel {
    if (marketCount <= 0) return 'keine aktivierten Märkte';
    if (marketCount == 1) return '1 Markt ohne Preis';
    return '$missingMarketCount von $marketCount Märkten ohne Preis';
  }

  String get detailLabel {
    final quantity = item.quantity > 1 ? 'Menge ×${item.quantity}' : 'Menge 1';
    final relevance = item.product.isStaple ? ' · Grundbedarf' : '';
    final purchaseLabel = purchaseCount <= 0
        ? ''
        : ' · bisher $purchaseCount ${purchaseCount == 1 ? 'Kauf' : 'Käufe'}';
    final historyLabel = historicalPriceLevel == null
        ? ''
        : ' · Historie-Median '
              '${historicalPriceLevel!.toStringAsFixed(2).replaceAll('.', ',')} €';
    return '$quantity · $marketLabel$relevance$purchaseLabel$historyLabel';
  }
}

/// Returns a stable order for unresolved list positions without creating a
/// route price from history.
///
/// The sort keys are intentionally explicit: first the number of markets
/// without evidence, then the starter-catalog relevance, then the combined
/// data-gap relevance, followed by its individual signals for readable
/// tie-breaking, and finally product name and id. This keeps the result
/// reproducible when the same observations are assembled in a different
/// order while allowing a high-impact gap to outrank a merely frequent one.
List<PriceGapPriority> prioritizePriceGaps(
  Iterable<ListItem> items, {
  required int marketCount,
  int Function(ListItem item)? missingMarketCountFor,
  int Function(ListItem item)? purchaseCountFor,
  double? Function(ListItem item)? historicalPriceLevelFor,
}) {
  final normalizedMarketCount = marketCount < 0 ? 0 : marketCount;
  final result = items.map((item) {
    final rawMissing =
        missingMarketCountFor?.call(item) ?? normalizedMarketCount;
    final missing = rawMissing.clamp(0, normalizedMarketCount).toInt();
    final rawPurchaseCount = purchaseCountFor?.call(item) ?? 0;
    final purchaseCount = rawPurchaseCount < 0 ? 0 : rawPurchaseCount;
    final rawHistoricalPrice = historicalPriceLevelFor?.call(item);
    final historicalPriceLevel =
        rawHistoricalPrice != null &&
            rawHistoricalPrice.isFinite &&
            rawHistoricalPrice > 0
        ? rawHistoricalPrice
        : null;
    return PriceGapPriority(
      item: item,
      missingMarketCount: missing,
      marketCount: normalizedMarketCount,
      purchaseCount: purchaseCount,
      historicalPriceLevel: historicalPriceLevel,
    );
  }).toList();

  result.sort((a, b) {
    final missing = b.missingMarketCount.compareTo(a.missingMarketCount);
    if (missing != 0) return missing;
    final staple = (b.item.product.isStaple ? 1 : 0).compareTo(
      a.item.product.isStaple ? 1 : 0,
    );
    if (staple != 0) return staple;
    final gapScore = b.dataGapScore.compareTo(a.dataGapScore);
    if (gapScore != 0) return gapScore;
    final purchases = b.purchaseCount.compareTo(a.purchaseCount);
    if (purchases != 0) return purchases;
    if (a.historicalPriceLevel != null || b.historicalPriceLevel != null) {
      if (a.historicalPriceLevel == null) return 1;
      if (b.historicalPriceLevel == null) return -1;
      final historical = b.historicalPriceLevel!.compareTo(
        a.historicalPriceLevel!,
      );
      if (historical != 0) return historical;
    }
    final quantity = b.item.quantity.compareTo(a.item.quantity);
    if (quantity != 0) return quantity;
    final names = a.item.product.name.toLowerCase().compareTo(
      b.item.product.name.toLowerCase(),
    );
    if (names != 0) return names;
    return a.item.product.id.compareTo(b.item.product.id);
  });
  return result;
}
