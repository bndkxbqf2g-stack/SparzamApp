import '../../models/market_price.dart';
import '../../models/product.dart';

class PriceCoverage {
  const PriceCoverage({
    required this.products,
    required this.productsWithEan,
    required this.manualPrices,
    required this.openPrices,
    required this.staleOpenPrices,
  });

  final int products;
  final int productsWithEan;
  final int manualPrices;
  final int openPrices;
  final int staleOpenPrices;

  double get eanCoverage =>
      products == 0 ? 0 : productsWithEan / products;
}

PriceCoverage calculatePriceCoverage(
  List<Product> products,
  List<MarketPrice> prices, {
  required int openPricesMaxAgeDays,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final external =
      prices.where((price) => price.source == MarketPriceSource.openPrices);

  return PriceCoverage(
    products: products.length,
    productsWithEan: products
        .where((product) => (product.ean ?? '').trim().isNotEmpty)
        .length,
    manualPrices:
        prices.where((price) => price.source == MarketPriceSource.manual).length,
    openPrices: external.length,
    staleOpenPrices: external
        .where(
          (price) => !price.isUsable(
            now: today,
            openPricesMaxAgeDays: openPricesMaxAgeDays,
          ),
        )
        .length,
  );
}
