import '../../models/market_price.dart';
import '../../models/product.dart';
import '../../services/barcode_normalizer.dart';
import '../../services/market_price_comparability.dart';

class PriceCoverage {
  const PriceCoverage({
    required this.products,
    required this.productsWithEan,
    required this.manualPrices,
    required this.openPrices,
    required this.staleOpenPrices,
    this.incompatiblePrices = 0,
  });

  final int products;
  final int productsWithEan;
  final int manualPrices;
  final int openPrices;
  final int staleOpenPrices;
  final int incompatiblePrices;

  double get eanCoverage =>
      products == 0 ? 0 : productsWithEan / products;
}

class StorePriceCoverage {
  const StorePriceCoverage({
    required this.storeName,
    required this.products,
    required this.receiptPrices,
    required this.openPrices,
    this.incompatiblePrices = 0,
  });

  final String storeName;
  final int products;
  final int receiptPrices;
  final int openPrices;
  final int incompatiblePrices;
}

List<StorePriceCoverage> calculateStorePriceCoverage(
  List<MarketPrice> prices, {
  List<String> storeNames = const <String>[],
  List<Product> products = const <Product>[],
}) {
  final productById = <String, Product>{
    for (final product in products) product.id: product,
  };
  final names = <String>{
    ...storeNames,
    ...prices.map((price) => price.storeName),
  };
  // Direct prospect offers remain evidence only. They must not make a store
  // look covered by a current comparable price.
  final eligiblePrices = prices.where((price) => !price.isProspectOffer && price.isProspectRegularBasis);
  final result = names.map((name) {
    final matches = eligiblePrices.where((price) {
      if (price.storeName != name) return false;
      final product = productById[price.productId];
      // Callers without a catalog retain the legacy coverage behavior. Once
      // the catalog is available, unknown products and incompatible package
      // quantities are data gaps rather than store coverage.
      return (products.isEmpty && product == null) ||
          (product != null && marketPriceMatchesProduct(price, product));
    }).toList();
    final incompatiblePrices = products.isEmpty
        ? 0
        : eligiblePrices.where((price) {
            final product = productById[price.productId];
            return price.storeName == name &&
                product != null &&
                !marketPriceMatchesProduct(price, product);
          }).length;
    return StorePriceCoverage(
      storeName: name,
      products: matches.map((price) => price.productId).toSet().length,
      receiptPrices: matches
          .where((price) => price.source == MarketPriceSource.receipt)
          .length,
      openPrices: matches
          .where((price) => price.source == MarketPriceSource.openPrices)
          .length,
      incompatiblePrices: incompatiblePrices,
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
  final productById = <String, Product>{
    for (final product in products) product.id: product,
  };
  // Offer amounts are kept in the offer/evidence surface and are not
  // comparable current prices for catalog coverage.
  final catalogPrices = prices.where(
    (price) =>
        !price.isProspectOffer && price.isProspectRegularBasis && productById.containsKey(price.productId),
  );
  final incompatiblePrices = catalogPrices.where((price) {
    final product = productById[price.productId]!;
    return !marketPriceMatchesProduct(price, product);
  }).length;
  final comparablePrices = catalogPrices.where((price) {
    final product = productById[price.productId];
    return product != null && marketPriceMatchesProduct(price, product);
  });
  final external = comparablePrices.where(
    (price) => price.source == MarketPriceSource.openPrices,
  );

  return PriceCoverage(
    products: products.length,
    productsWithEan: products
        .where(
          (product) =>
              product.ean != null && normalizeBarcode(product.ean!) != null,
        )
        .length,
    manualPrices: comparablePrices.where((price) => price.isManual).length,
    openPrices: external.length,
    incompatiblePrices: incompatiblePrices,
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
