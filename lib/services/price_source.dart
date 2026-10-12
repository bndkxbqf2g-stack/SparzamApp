import '../models/market_price.dart';
import '../models/product.dart';
import '../models/store.dart';

/// Contract for a read-only current-price provider.
///
/// A source may return historical observations when it is serving a local
/// offline cache. Route projection still applies the central freshness and
/// confidence rules before using them.
abstract interface class PriceSource {
  bool get enabled;

  Future<List<MarketPrice>> fetchRecentPrices({
    required Product product,
    required List<Store> stores,
    DateTime? now,
  });

  void close();
}
