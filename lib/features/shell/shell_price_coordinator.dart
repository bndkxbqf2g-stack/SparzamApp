import '../../models/market_price.dart';
import '../../models/price_point.dart';
import '../../models/product.dart';
import '../../services/market_price_store.dart';
import '../../services/open_prices_sync_service.dart';
import '../../services/price_history_store.dart';
import 'shell_pricing.dart';

class PriceMutationResult {
  const PriceMutationResult({
    required this.prices,
    required this.history,
  });

  final List<MarketPrice> prices;
  final List<PricePoint> history;
}

class ShellPriceCoordinator {
  const ShellPriceCoordinator({
    required this.marketPriceStore,
    required this.priceHistoryStore,
  });

  final MarketPriceStore marketPriceStore;
  final PriceHistoryStore priceHistoryStore;

  Future<PriceMutationResult> save({
    required MarketPrice price,
    required List<MarketPrice> prices,
    required List<PricePoint> history,
  }) async {
    final nextPrices = await marketPriceStore.upsert(price, prices);
    final nextHistory = await priceHistoryStore.upsertObservation(
      priceHistoryPoint(price),
      history,
    );
    return PriceMutationResult(
      prices: nextPrices,
      history: nextHistory,
    );
  }

  Future<List<MarketPrice>> delete({
    required String productId,
    required String storeName,
    required List<MarketPrice> prices,
  }) =>
      marketPriceStore.remove(productId, storeName, prices);

  Future<PriceMutationResult> syncOpenPrices({
    required List<Product> products,
    required int maxAgeDays,
    required List<MarketPrice> prices,
    required List<PricePoint> history,
    OpenPricesSyncService service = const OpenPricesSyncService(),
  }) async {
    final synced = await service.sync(
      products: products,
      maxAgeDays: maxAgeDays,
    );
    var nextPrices = prices;
    var nextHistory = history;
    for (final price in synced.prices) {
      nextPrices = await marketPriceStore.upsert(price, nextPrices);
      nextHistory = await priceHistoryStore.upsertObservation(
        priceHistoryPoint(price),
        nextHistory,
      );
    }
    return PriceMutationResult(
      prices: nextPrices,
      history: nextHistory,
    );
  }
}
