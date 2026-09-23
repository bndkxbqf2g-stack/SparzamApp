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

class StorePriceCoverage {
  const StorePriceCoverage({
    required this.storeName,
    required this.products,
    required this.receiptPrices,
    required this.openPrices,
  });

  final String storeName;
  final int products;
  final int receiptPrices;
  final int openPrices;
}

List<StorePriceCoverage> calculateStorePriceCoverage(
  List<MarketPrice> prices, {
  List<String> storeNames = const <String>[],
}) {
  final names = <String>{
    ...storeNames,
    ...prices.map((price) => price.storeName),
  };
  final result = names.map((name) {
    final matches = prices.where((price) => price.storeName == name).toList();
    return StorePriceCoverage(
      storeName: name,
      products: matches.map((price) => price.productId).toSet().length,
      receiptPrices: matches
          .where((price) => price.source == MarketPriceSource.receipt)
          .length,
      openPrices: matches
          .where((price) => price.source == MarketPriceSource.openPrices)
          .length,
    );
  }).toList();
  result.sort((a, b) {
    final byProducts = b.products.compareTo(a.products);
    return byProducts != 0 ? byProducts : a.storeName.compareTo(b.storeName);
  });
  return result;
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
    manualPrices: prices.where((price) => price.isManual).length,
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
