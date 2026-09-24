import '../../models/market_price.dart';

/// Source and age are independent factors; rates are D025 planning heuristics.
class MarketPriceQuality {
  const MarketPriceQuality(this.sourceRate, this.ageRate, this.discountRate);

  final double sourceRate;
  final double ageRate;
  final double discountRate;

  double get uncertaintyRate => sourceRate + ageRate + discountRate;
  double get confidence => (1 - uncertaintyRate).clamp(0.0, 1.0);
}

MarketPriceQuality marketPriceQuality(MarketPrice price, DateTime now) {
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(price.updatedAt.year,
          price.updatedAt.month, price.updatedAt.day))
      .inDays.clamp(0, 36500);
  final sourceRate = switch (price.source) {
    MarketPriceSource.manual => 0.0,
    MarketPriceSource.receipt => 0.05,
    MarketPriceSource.openPrices => 0.05,
  };
  final ageRate = switch (price.source) {
    MarketPriceSource.manual => days <= 30 ? 0.0 : 0.05,
    MarketPriceSource.receipt => days <= 30 ? 0.0 : days <= 60 ? 0.10 : 0.20,
    MarketPriceSource.openPrices => days <= 7 ? 0.0 : 0.05,
  };
  final discountRate = price.source == MarketPriceSource.receipt &&
          price.discounted ? 0.10 : 0.0;
  return MarketPriceQuality(sourceRate, ageRate, discountRate);
}
