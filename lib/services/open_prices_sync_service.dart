import '../data/stores.dart';
import '../models/market_price.dart';
import '../models/product.dart';
import 'barcode_normalizer.dart';
import 'open_prices_cache.dart';
import 'open_prices_service.dart';
import 'open_food_facts_product_discovery.dart';

typedef OpenPricesProductFetcher = Future<List<MarketPrice>> Function(
  Product product,
  int maxAgeDays,
);
typedef OpenPricesProductDiscoverer = Future<Product?> Function(Product product);

class OpenPricesSyncResult {
  const OpenPricesSyncResult({
    required this.productsChecked,
    required this.productsWithEan,
    required this.pricesFound,
    required this.prices,
    required this.productsProcessed,
    required this.cancelled,
    required this.failedProductIds,
  });

  final int productsChecked;
  final int productsWithEan;
  final int pricesFound;
  final List<MarketPrice> prices;
  final int productsProcessed;
  final bool cancelled;
  final List<String> failedProductIds;
}

class OpenPricesSyncService {
  const OpenPricesSyncService({this.fetcher, this.discoverer});

  final OpenPricesProductFetcher? fetcher;
  final OpenPricesProductDiscoverer? discoverer;

  Future<OpenPricesSyncResult> sync({
    required List<Product> products,
    required int maxAgeDays,
    void Function(int processed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final result = <MarketPrice>[];
    final failures = <String>[];
    var processed = 0;
    final customFetcher = fetcher;
    final customDiscoverer = discoverer;
    OpenPricesService? service;
    OpenFoodFactsProductDiscovery? discovery;
    if (customFetcher == null) {
      service = OpenPricesService(
        maxAge: Duration(days: maxAgeDays),
        cache: SharedPreferencesOpenPricesCache(),
      );
      discovery = OpenFoodFactsProductDiscovery();
    }

    final candidatesById = <String, Product>{};
    final discoveredIds = <String>{};
    var cancelledDuringDiscovery = false;

    void addCandidate(Product candidate) {
      // A catalog can contain the same product ID in the base and custom
      // layers. One request is enough; keeping the first entry preserves the
      // caller's deterministic source order.
      candidatesById.putIfAbsent(candidate.id, () => candidate);
    }

    for (final product in products) {
      if (shouldCancel?.call() == true) {
        cancelledDuringDiscovery = true;
        break;
      }
      if (product.ean != null && normalizeBarcode(product.ean!) != null) {
        addCandidate(product);
        continue;
      }
      try {
        final resolved = customDiscoverer != null
            ? await customDiscoverer(product)
            : customFetcher == null
                ? await discovery!.discover(product)
                : null;
        if (resolved != null &&
            resolved.ean != null &&
            normalizeBarcode(resolved.ean!) != null) {
          addCandidate(resolved);
          discoveredIds.add(resolved.id);
        }
      } catch (_) {
        failures.add(product.id);
      }
    }

    final candidates = candidatesById.values.toList(growable: false);

    try {
      for (var index = 0; index < candidates.length; index++) {
        if (shouldCancel?.call() == true) break;
        try {
          final found = customFetcher != null
              ? await customFetcher(candidates[index], maxAgeDays)
              : await service!.fetchRecentPrices(
                  product: candidates[index],
                  stores: stores,
                );
          // A discovered barcode is useful retrieval evidence, but it is not
          // yet a user-confirmed exact identity. Keep those prices out of the
          // exact route-price stream until the identity is confirmed.
          if (!discoveredIds.contains(candidates[index].id)) {
            result.addAll(found);
          }
        } catch (_) {
          failures.add(candidates[index].id);
        }
        processed++;
        onProgress?.call(processed, candidates.length);

        if (customFetcher == null && index < candidates.length - 1 &&
            shouldCancel?.call() != true) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
    } finally {
      service?.close();
      discovery?.close();
    }

    return OpenPricesSyncResult(
      productsChecked: products.length,
      productsWithEan: candidates.length,
      pricesFound: result.length,
      prices: result,
      productsProcessed: processed,
      cancelled: cancelledDuringDiscovery || processed < candidates.length,
      failedProductIds: failures,
    );
  }
}
