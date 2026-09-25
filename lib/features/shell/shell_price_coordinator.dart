import '../../models/market_price.dart';
import '../../models/price_point.dart';
import '../../models/price_sync_result.dart';
import '../../models/product.dart';
import '../../services/market_price_store.dart';
import '../../services/open_prices_sync_service.dart';
import '../../services/price_history_store.dart';
import '../../services/price_observation_store.dart';
import '../../services/market_price_observation_adapter.dart';
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
  ShellPriceCoordinator({
    required this.marketPriceStore,
    required this.priceHistoryStore,
    PriceObservationStore? observationStore,
  }) : observationStore = observationStore ?? PriceObservationStore();

  final MarketPriceStore marketPriceStore;
  final PriceHistoryStore priceHistoryStore;
  final PriceObservationStore observationStore;

  Future<PriceMutationResult> save({
    required MarketPrice price,
    required List<MarketPrice> prices,
    required List<PricePoint> history,
  }) async {
    await observationStore.append([observationFromMarketPrice(price)]);
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

  Future<PriceSyncResult> syncOpenPrices({
    required List<Product> products,
    required int maxAgeDays,
    required List<MarketPrice> prices,
    required List<PricePoint> history,
    OpenPricesSyncService service = const OpenPricesSyncService(),
    void Function(int processed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final synced = await service.sync(
      products: products,
      maxAgeDays: maxAgeDays,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
    await observationStore.append(
      synced.prices.map(observationFromMarketPrice),
    );
    final nextPrices = await marketPriceStore.upsertMany(synced.prices, prices);
    final nextHistory = await priceHistoryStore.upsertObservations(
      synced.prices.map(priceHistoryPoint),
      history,
    );
    return PriceSyncResult(
      prices: nextPrices,
      history: nextHistory,
      productsChecked: synced.productsChecked,
      productsWithEan: synced.productsWithEan,
      pricesFound: synced.pricesFound,
      productsProcessed: synced.productsProcessed,
      cancelled: synced.cancelled,
      failedProductIds: synced.failedProductIds,
    );
  }
}
