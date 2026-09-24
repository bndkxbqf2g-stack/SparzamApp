import '../../models/market_price.dart';
import '../../models/price_data_settings.dart';
import '../../models/price_point.dart';
import '../catalog/market_price_freshness.dart';

List<MarketPrice> activePrices(
  List<MarketPrice> prices,
  PriceDataSettings settings,
) {
  if (!settings.openPricesEnabled) {
    return prices
        .where((price) => price.source != MarketPriceSource.openPrices && price.isUsable(
          now: DateTime.now(),
          openPricesMaxAgeDays: settings.openPricesMaxAgeDays,
        ))
        .toList(growable: false);
  }
  return usableMarketPrices(
    prices,
    openPricesMaxAgeDays: settings.openPricesMaxAgeDays,
  );
}

PricePoint priceHistoryPoint(MarketPrice price) => PricePoint(
      productId: price.productId,
      storeName: price.storeName,
      price: price.price,
      date: price.updatedAt,
      source: switch (price.source) {
        MarketPriceSource.openPrices => PricePointSource.openPrices,
        MarketPriceSource.receipt => PricePointSource.receipt,
        MarketPriceSource.manual => PricePointSource.manual,
      }, 
    );
