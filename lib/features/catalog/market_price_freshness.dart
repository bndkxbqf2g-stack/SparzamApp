import '../../models/market_price.dart';

List<MarketPrice> usableMarketPrices(
  List<MarketPrice> prices, {
  required int openPricesMaxAgeDays,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  return prices
      .where(
        (price) => price.isUsable(
          now: today,
          openPricesMaxAgeDays: openPricesMaxAgeDays,
        ),
      )
      .toList(growable: false);
}
