import '../../models/list_item.dart';
import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../services/quantity_normalizer.dart';

/// Returns exact, regular historical price levels for the requested items.
///
/// This is a prioritization signal only. It never creates a `MarketPrice` or
/// makes an old observation route-usable. Family-only, uncertain, discounted,
/// estimated and package-incomparable observations are intentionally omitted.
Map<String, double> historicalPriceLevelsByProduct({
  required Iterable<ListItem> items,
  required Iterable<PriceObservation> observations,
  DateTime? now,
}) {
  final productsById = <String, Product>{
    for (final item in items) item.product.id: item.product,
  };
  final pricesByProduct = <String, List<double>>{};
  final reference = now ?? DateTime.now();

  for (final observation in observations) {
    final productId = observation.productId;
    final product = productId == null ? null : productsById[productId];
    if (product == null ||
        !observation.isValid ||
        observation.identityConfidence < 1 ||
        observation.source == PriceObservationSource.estimate ||
        observation.kind == PriceObservationKind.offer ||
        observation.discounted ||
        observation.observedAt.isAfter(reference) ||
        !_matchesPackage(product, observation)) {
      continue;
    }
    final exactProductId = productId;
    if (exactProductId == null) continue;
    pricesByProduct
        .putIfAbsent(exactProductId, () => <double>[])
        .add(observation.price);
  }

  return {
    for (final entry in pricesByProduct.entries)
      entry.key: _median(entry.value),
  };
}

bool _matchesPackage(Product product, PriceObservation observation) {
  final observedAmount = observation.quantity;
  final observedUnit = observation.unit;
  if (observedAmount == null || observedUnit == null || observedUnit.isEmpty) {
    return true;
  }
  final expectedAmount = product.packageAmount;
  final expectedUnit = product.packageUnit;
  if (expectedAmount == null || expectedUnit == null) return false;
  final expected = normalizeQuantity(expectedAmount, expectedUnit);
  final observed = normalizeQuantity(observedAmount, observedUnit);
  if (expected == null ||
      observed == null ||
      expected.dimension != observed.dimension) {
    return false;
  }
  return (expected.amount - observed.amount).abs() < 0.000001;
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}
