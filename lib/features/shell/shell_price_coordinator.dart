import '../../models/market_price.dart';
import '../../models/price_observation.dart';
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
    this.observations = const <PriceObservation>[],
  });

  final List<MarketPrice> prices;
  final List<PricePoint> history;
  /// Complete local observation snapshot written with the same mutation.
  final List<PriceObservation> observations;
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
  }) =>
      saveMany(
        prices: [price],
        currentPrices: prices,
        history: history,
      );

  /// Persists a reviewed price batch and returns one coherent UI snapshot.
  ///
  /// Receipt review can produce several market prices at once. Keeping the
  /// observation, current-price and history projections in one coordinator
  /// operation prevents the shell from rendering an intermediate partial batch.
  Future<PriceMutationResult> saveMany({
    required Iterable<MarketPrice> prices,
    required List<MarketPrice> currentPrices,
    required List<PricePoint> history,
  }) async {
    final incoming = prices.toList(growable: false);
    final observations = await observationStore.upsertById(
      incoming.map(observationFromMarketPrice),
    );
    final nextPrices = await marketPriceStore.upsertMany(
      incoming,
      currentPrices,
    );
    final nextHistory = await priceHistoryStore.upsertObservations(
      incoming
          .where(
            (price) =>
                !price.isProspectOffer && price.isProspectRegularBasis,
          )
          .map(priceHistoryPoint),
      history,
    );
    return PriceMutationResult(
      prices: nextPrices,
      history: nextHistory,
      observations: observations,
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
    final observations = await observationStore.append(
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
      observations: observations,
    );
  }
}
