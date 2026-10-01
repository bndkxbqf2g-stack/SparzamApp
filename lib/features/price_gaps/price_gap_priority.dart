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
  });

  final ListItem item;
  final int missingMarketCount;
  final int marketCount;
  final int purchaseCount;

  int get knownMarketCount =>
      (marketCount - missingMarketCount).clamp(0, marketCount).toInt();

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
    return '$quantity · $marketLabel$relevance$purchaseLabel';
  }
}

/// Returns a stable, price-free order for unresolved list positions.
///
/// The sort keys are intentionally explicit: first the number of markets
/// without evidence, then the starter-catalog relevance, then the known
/// purchase frequency, then list quantity, followed by product name and id.
/// This keeps the result reproducible when the same observations are
/// assembled in a different order.
List<PriceGapPriority> prioritizePriceGaps(
  Iterable<ListItem> items, {
  required int marketCount,
  int Function(ListItem item)? missingMarketCountFor,
  int Function(ListItem item)? purchaseCountFor,
}) {
  final normalizedMarketCount = marketCount < 0 ? 0 : marketCount;
  final result = items.map((item) {
    final rawMissing =
        missingMarketCountFor?.call(item) ?? normalizedMarketCount;
    final missing = rawMissing.clamp(0, normalizedMarketCount).toInt();
    final rawPurchaseCount = purchaseCountFor?.call(item) ?? 0;
    final purchaseCount = rawPurchaseCount < 0 ? 0 : rawPurchaseCount;
    return PriceGapPriority(
      item: item,
      missingMarketCount: missing,
      marketCount: normalizedMarketCount,
      purchaseCount: purchaseCount,
    );
  }).toList();

  result.sort((a, b) {
    final missing = b.missingMarketCount.compareTo(a.missingMarketCount);
    if (missing != 0) return missing;
    final staple = (b.item.product.isStaple ? 1 : 0).compareTo(
      a.item.product.isStaple ? 1 : 0,
    );
    if (staple != 0) return staple;
    final purchases = b.purchaseCount.compareTo(a.purchaseCount);
    if (purchases != 0) return purchases;
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
