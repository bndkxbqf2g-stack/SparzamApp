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
  });

  final int productsChecked;
  final int productsWithEan;
  final int pricesFound;
  final List<MarketPrice> prices;
}

class OpenPricesSyncService {
  const OpenPricesSyncService({this.fetcher});

  final OpenPricesProductFetcher? fetcher;

  Future<OpenPricesSyncResult> sync({
    required List<Product> products,
    required int maxAgeDays,
  }) async {
    final withEan = products
        .where((product) => (product.ean ?? '').trim().isNotEmpty)
        .toList();

    final result = <MarketPrice>[];
    final customFetcher = fetcher;
    OpenPricesService? service;
    if (customFetcher == null) {
      service = OpenPricesService(
        maxAge: Duration(days: maxAgeDays),
      );
    }

    try {
      for (var index = 0; index < withEan.length; index++) {
        final found = customFetcher != null
            ? await customFetcher(withEan[index], maxAgeDays)
            : await service!.fetchRecentPrices(
                product: withEan[index],
                stores: stores,
              );
        result.addAll(found);

        if (customFetcher == null && index < withEan.length - 1) {
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
    );
  }
}
