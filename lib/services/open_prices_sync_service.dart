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

/// Returns the bounded concurrency used by the live adapter. Injected
/// fetchers intentionally stay serial so cancellation and fixture ordering
/// remain identical to the established test/offline path.
int openPricesNetworkBatchSize({
  required bool live,
  required int configured,
}) =>
    live ? configured.clamp(1, 4).toInt() : 1;


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
  const OpenPricesSyncService({
    this.fetcher,
    this.discoverer,
    this.productDiscovery,
    this.networkConcurrency = 2,
  }) : assert(networkConcurrency > 0);

  final OpenPricesProductFetcher? fetcher;
  final OpenPricesProductDiscoverer? discoverer;

  /// Optional injected Open Food Facts discovery client. It is useful for
  /// deterministic tests and keeps the live adapter replaceable without
  /// changing the price-fetch contract.
  final OpenFoodFactsProductDiscovery? productDiscovery;

  /// Limits simultaneous live Open Prices requests. Custom fetchers stay
  /// sequential so tests and injected providers keep their established
  /// cancellation/order semantics.
  final int networkConcurrency;

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
    var ownsDiscovery = false;
    if (customFetcher == null) {
      service = OpenPricesService(
        maxAge: Duration(days: maxAgeDays),
        cache: SharedPreferencesOpenPricesCache(),
      );
    }
    if (productDiscovery != null) {
      discovery = productDiscovery;
    } else if (customFetcher == null) {
      discovery = OpenFoodFactsProductDiscovery();
      ownsDiscovery = true;
    }

    final candidatesById = <String, Product>{    final discoveredIds = <String>{};
    var cancelledDuringDiscovery = false;
    final discoveryIsLive = discovery != null && customDiscoverer == null;
    final discoveryBatchSize = openPricesNetworkBatchSize(
      live: discoveryIsLive,
      configured: networkConcurrency,
    );

    void addCandidate(Product candidate) {
      // A catalog can contain the same product ID in the base and custom
      // layers. One request is enough; keeping the first entry preserves the
      // caller's deterministic source order.
      candidatesById.putIfAbsent(candidate.id, () => candidate);
    }

    for (var start = 0;
        start < products.length;
        start += discoveryBatchSize) {
      if (shouldCancel?.call() == true) {
        cancelledDuringDiscovery = true;
        break;
      }
      final end = (start + discoveryBatchSize < products.length)
          ? start + discoveryBatchSize
          : products.length;
      final batch = products.sublist(start, end);
      final failed = List<bool>.filled(batch.length, false);
      // Future.wait keeps the input order. Live discovery can overlap a
      // small bounded batch while custom discoverers remain serial for
      // cancellation and fixture determinism.
      final resolved = await Future.wait<Product?>([
        for (var index = 0; index < batch.length; index++)
          () async {
            final product = batch[index];
            final hasEan = product.ean != null &&
                normalizeBarcode(product.ean!) != null;
            if (hasEan) return product;
            if (customDiscoverer != null) {
              try {
                return await customDiscoverer(product);
              } catch (_) {
                failed[index] = true;
                return null;
              }
            }
            if (discovery != null) {
              try {
                return await discovery!.discover(product);
              } catch (_) {
                failed[index] = true;
                return null;
              }
            }
            return null;
          }(),
      ]);
      for (var index = 0; index < batch.length; index++) {
        final product = batch[index];
        if (failed[index]) failures.add(product.id);
        final candidate = resolved[index];
        if (candidate == null ||
            candidate.ean == null ||
            normalizeBarcode(candidate.ean!) == null) {
          continue;
        }
        addCandidate(candidate);
        if (product.ean == null ||
            normalizeBarcode(product.ean!) == null) {
          // A discovered barcode is useful retrieval evidence, but it is
          // not yet a user-confirmed exact identity. Keep those prices out
          // of the exact route-price stream until the identity is confirmed.
          discoveredIds.add(candidate.id);
        }
      }
    }

    final candidates = candidatesById.values.toList(growable: false);
    final batchSize = openPricesNetworkBatchSize(
      live: customFetcher == null,
      configured: networkConcurrency,
    );
    var cancelledDuringFetch = false;

    try {
      for (var start = 0;
          start < candidates.length;
          start += batchSize) {
        if (shouldCancel?.call() == true) {
          cancelledDuringFetch = true;
          break;
        }
        final end = (start + batchSize < candidates.length)
            ? start + batchSize
            : candidates.length;
        final batch = candidates.sublist(start, end);
        // Future.wait preserves the input order, so the result and progress
        // stream stay deterministic even while the bounded network requests
        // overlap.
        final fetched = await Future.wait<List<MarketPrice>?>([
          for (final candidate in batch)
            () async {
              try {
                return customFetcher != null
                    ? await customFetcher(candidate, maxAgeDays)
                    : await service!.fetchRecentPrices(
                        product: candidate,
                        stores: stores,
                      );
              } catch (_) {
                return null;
              }
            }(),
        ]);
        for (var offset = 0; offset < batch.length; offset++) {
          final candidate = batch[offset];
          final found = fetched[offset];
          if (found == null) {
            failures.add(candidate.id);
          } else if (!discoveredIds.contains(candidate.id)) {
            // A discovered barcode is useful retrieval evidence, but it is
            // not yet a user-confirmed exact identity. Keep those prices out
            // of the exact route-price stream until the identity is confirmed.
            result.addAll(found);
          }
          processed++;
          onProgress?.call(processed, candidates.length);
        }
        if (shouldCancel?.call() == true) {
          cancelledDuringFetch = true;
          break;
        }
        if (customFetcher == null && end < candidates.length) {
          // Keep the live source's request rate bounded between batches.
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
    } finally {
      service?.close();
      if (ownsDiscovery) discovery?.close();
    }
    return OpenPricesSyncResult(
      productsChecked: products.length,
      productsWithEan: candidates.length,
      pricesFound: result.length,
      prices: result,
      productsProcessed: processed,
      cancelled: cancelledDuringDiscovery ||
          cancelledDuringFetch ||
          processed < candidates.length,
      failedProductIds: failures,
    );
  }
}
