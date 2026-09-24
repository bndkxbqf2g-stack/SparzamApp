import 'market_price_quality.dart';
import 'route_price_resolver.dart';

/// A transparent planning margin, not money charged at checkout. The margin
/// prevents a weak historical observation from forcing an extra store for a
/// few cents. Percentages are deliberately conservative heuristics.
double priceUncertaintyReserve(RoutePriceQuote quote, DateTime now) {
  if (quote.isEstimated || quote.usesOffer) return 0;
  final observation = quote.observation;
  if (observation == null) return quote.total * 0.15; // Catalog example price.

  return quote.total * marketPriceQuality(observation, now).uncertaintyRate;
}
