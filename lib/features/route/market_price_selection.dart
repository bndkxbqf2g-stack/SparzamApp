import '../../models/market_price.dart';
import 'market_price_quality.dart';

/// Selects one route-usable price per store/product key using the same
/// quality-adjusted score everywhere the planning projection needs to collapse
/// exact history. Receipt freshness is enforced before ranking.
Map<String, MarketPrice> preferredMarketPricesByKey(
  Iterable<MarketPrice> input,
  DateTime now,
) {
  final selected = <String, MarketPrice>{};
  for (final price in input) {
    if (!price.price.isFinite || price.price <= 0) continue;
    if (price.source == MarketPriceSource.receipt &&
        !price.isUsable(now: now, openPricesMaxAgeDays: 36500)) {
      continue;
    }

    final previous = selected[price.key];
    final score =
        price.price * (1 + marketPriceQuality(price, now).uncertaintyRate);
    final previousScore = previous == null
        ? double.infinity
        : previous.price *
            (1 + marketPriceQuality(previous, now).uncertaintyRate);

    if (score < previousScore ||
        (score == previousScore &&
            previous != null &&
            price.updatedAt.isAfter(previous.updatedAt))) {
      selected[price.key] = price;
    }
  }
  return selected;
}
