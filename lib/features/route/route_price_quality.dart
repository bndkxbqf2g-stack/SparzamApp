import '../../models/market_price.dart';
import 'route_price_resolver.dart';

/// A transparent planning margin, not money charged at checkout. The margin
/// prevents a weak historical observation from forcing an extra store for a
/// few cents. Percentages are deliberately conservative heuristics.
double priceUncertaintyReserve(RoutePriceQuote quote, DateTime now) {
  if (quote.isEstimated || quote.usesOffer) return 0;
  final observation = quote.observation;
  if (observation == null) return quote.total * 0.15; // Catalog example price.

  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(observation.updatedAt.year,
          observation.updatedAt.month, observation.updatedAt.day))
      .inDays.clamp(0, 36500);
  final rate = switch (observation.source) {
    MarketPriceSource.manual => days <= 30 ? 0.0 : 0.05,
    MarketPriceSource.receipt => days <= 30
        ? 0.05
        : days <= 60
            ? 0.15
            : 0.25,
    MarketPriceSource.openPrices => days <= 7 ? 0.05 : 0.10,
  };
  final discountRate = observation.source == MarketPriceSource.receipt &&
          observation.discounted
      ? 0.10
      : 0.0;
  return quote.total * (rate + discountRate);
}
