import 'market_price.dart';
import 'price_point.dart';

class PriceSyncResult {
  const PriceSyncResult({
    required this.prices,
    required this.history,
    required this.productsChecked,
    required this.productsWithEan,
    required this.pricesFound,
    required this.productsProcessed,
    required this.cancelled,
    this.failedProductIds = const [],
  });

  final List<MarketPrice> prices;
  final List<PricePoint> history;
  final int productsChecked;
  final int productsWithEan;
  final int pricesFound;
  final int productsProcessed;
  final bool cancelled;
  final List<String> failedProductIds;
}
