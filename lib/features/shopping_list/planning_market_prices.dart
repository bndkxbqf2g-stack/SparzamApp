import '../../models/market_price.dart';

/// An exact market price wins over a family-derived receipt observation.
/// Within either source, keep the most recent price for each product and store.
List<MarketPrice> planningMarketPrices({
  required Iterable<MarketPrice> exactPrices,
  required Iterable<MarketPrice> familyPrices,
}) {
  final selected = <String, MarketPrice>{};
  for (final price in familyPrices) {
    final previous = selected[price.key];
    if (previous == null || price.updatedAt.isAfter(previous.updatedAt)) {
      selected[price.key] = price;
    }
  }
  final exact = <String, MarketPrice>{};
  for (final price in exactPrices) {
    final previous = exact[price.key];
    if (previous == null || price.updatedAt.isAfter(previous.updatedAt)) {
      exact[price.key] = price;
    }
  }
  selected.addAll(exact);
  return selected.values.toList(growable: false);
}
