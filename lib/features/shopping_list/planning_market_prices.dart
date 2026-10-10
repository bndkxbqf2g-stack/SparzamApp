import '../../models/market_price.dart';
import '../route/market_price_selection.dart';

/// Exact product identity always wins over family-derived receipt evidence.
/// Competing observations within the same layer are collapsed using the same
/// quality-adjusted rule as the route resolver, so append-only history is not
/// reduced to "newest wins" before route planning can evaluate it.
List<MarketPrice> planningMarketPrices({
  required Iterable<MarketPrice> exactPrices,
  required Iterable<MarketPrice> familyPrices,
  DateTime? now,
  int openPricesMaxAgeDays = 60,
}) {
  final today = now ?? DateTime.now();
  final selected = preferredMarketPricesByKey(
    familyPrices,
    today,
    openPricesMaxAgeDays: openPricesMaxAgeDays,
  );
  selected.addAll(
    preferredMarketPricesByKey(
      exactPrices,
      today,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
    ),
  );
  return selected.values.toList(growable: false);
}
