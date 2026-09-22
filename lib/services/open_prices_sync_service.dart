import '../data/stores.dart';
import '../models/market_price.dart';
import '../models/product.dart';
import 'open_prices_service.dart';

typedef OpenPricesProductFetcher = Future<List<MarketPrice>> Function(
  Product product,
  int maxAgeDays,
);

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
  const OpenPricesSyncService({this.fetcher});

  final OpenPricesProductFetcher? fetcher;

  Future<OpenPricesSyncResult> sync({
    required List<Product> products,
    required int maxAgeDays,
    void Function(int processed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final withEan = products
        .where((product) => (product.ean ?? '').trim().isNotEmpty)
        .toList();

    final result = <MarketPrice>[];
    final failures = <String>[];
    var processed = 0;
    final customFetcher = fetcher;
    OpenPricesService? service;
    if (customFetcher == null) {
      service = OpenPricesService(
        maxAge: Duration(days: maxAgeDays),
      );
    }

    try {
      for (var index = 0; index < withEan.length; index++) {
        if (shouldCancel?.call() == true) break;
        try {
          final found = customFetcher != null
              ? await customFetcher(withEan[index], maxAgeDays)
              : await service!.fetchRecentPrices(
                  product: withEan[index],
                  stores: stores,
                );
          result.addAll(found);
        } catch (_) {
          failures.add(withEan[index].id);
        }
        processed++;
        onProgress?.call(processed, withEan.length);

        if (customFetcher == null && index < withEan.length - 1 &&
            shouldCancel?.call() != true) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
    } finally {
      service?.close();
    }

    return OpenPricesSyncResult(
      productsChecked: products.length,
      productsWithEan: withEan.length,
      pricesFound: result.length,
      prices: result,
      productsProcessed: processed,
      cancelled: processed < withEan.length,
      failedProductIds: failures,
    );
  }
}
