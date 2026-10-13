import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/road_route_matrix.dart';
import '../route/route_optimizer.dart';

class ShellRouting {
  const ShellRouting({
    required this.items,
    required this.offers,
    required this.mobility,
    required this.marketPrices,
    this.openPricesMaxAgeDays = 60,
    required this.roadDistances,
    required this.roadMatrix,
  });

  final List<ListItem> items;
  final List<Offer> offers;
  final MobilitySettings mobility;
  final List<MarketPrice> marketPrices;
  final int openPricesMaxAgeDays;
  final Map<String, double> roadDistances;
  final RoadRouteMatrix? roadMatrix;

  // Dashboard and shell pages ask for the same plans repeatedly during one
  // build. Keep one optimizer per immutable routing snapshot so those reads
  // share the expensive quote normalization and alternative search.
  late final RouteOptimizer? _currentCache = _optimizer(offers);
  late final RouteOptimizer? _regularCache = _optimizer(const <Offer>[]);

  RouteOptimizer? get current => _currentCache;
  RouteOptimizer? get regular => _regularCache;

  RouteOptimizer? _optimizer(List<Offer> selectedOffers) => items.isEmpty
      ? null
      : RouteOptimizer(
          items,
          selectedOffers,
          roadDistances: roadDistances,
          euroPerKm: mobility.effectiveEuroPerKm,
          maxStores: mobility.maxStores,
          minExtraStoreSavings: mobility.minExtraStoreSavings,
          additionalStoreCost: mobility.additionalStoreCost,
          timeValuePerHour: mobility.timeValuePerHour,
          travelMinutesPerKm: 60 / mobility.mode.averageSpeedKmh,
          enabledStoreNames: mobility.enabledStoreNames,
          marketPrices: marketPrices,
          openPricesMaxAgeDays: openPricesMaxAgeDays,
          roadMatrix: mobility.mode == MobilityMode.car ? roadMatrix : null,
        );
}
