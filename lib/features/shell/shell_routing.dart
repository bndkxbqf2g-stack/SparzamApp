import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/road_route_matrix.dart';
import '../route/route_optimizer.dart';

class ShellRouting {
  ShellRouting({
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

/// Reuses a [ShellRouting] object while the shell inputs remain unchanged.
///
/// The shell can rebuild for local UI state (for example a search field or a
/// tab change) without changing the route inputs. Quantity changes mutate a
/// [ListItem] in place in a few legacy callbacks, so the cache also keeps a
/// compact product/quantity signature instead of relying on list identity
/// alone.
class ShellRoutingSnapshotCache {
  ShellRouting? _cached;
  List<ListItem>? _cachedItems;
  List<Offer>? _cachedOffers;
  MobilitySettings? _cachedMobility;
  List<MarketPrice>? _cachedMarketPrices;
  Map<String, double>? _cachedRoadDistances;
  RoadRouteMatrix? _cachedRoadMatrix;
  int? _cachedOpenPricesMaxAgeDays;
  int? _cachedItemSignature;
  int? _cachedMobilitySignature;

  ShellRouting resolve({
    required List<ListItem> items,
    required List<Offer> offers,
    required MobilitySettings mobility,
    required List<MarketPrice> marketPrices,
    required int openPricesMaxAgeDays,
    required Map<String, double> roadDistances,
    required RoadRouteMatrix? roadMatrix,
  }) {
    final itemSignature = _itemSignature(items);
    final mobilitySignature = _mobilitySignature(mobility);
    final cached = _cached;
    if (cached != null &&
        identical(_cachedItems, items) &&
        identical(_cachedOffers, offers) &&
        identical(_cachedMobility, mobility) &&
        identical(_cachedMarketPrices, marketPrices) &&
        identical(_cachedRoadDistances, roadDistances) &&
        identical(_cachedRoadMatrix, roadMatrix) &&
        _cachedOpenPricesMaxAgeDays == openPricesMaxAgeDays &&
        _cachedItemSignature == itemSignature &&
        _cachedMobilitySignature == mobilitySignature) {
      return cached;
    }

    final next = ShellRouting(
      items: items,
      offers: offers,
      mobility: mobility,
      marketPrices: marketPrices,
      openPricesMaxAgeDays: openPricesMaxAgeDays,
      roadDistances: roadDistances,
      roadMatrix: roadMatrix,
    );
    _cached = next;
    _cachedItems = items;
    _cachedOffers = offers;
    _cachedMobility = mobility;
    _cachedMarketPrices = marketPrices;
    _cachedRoadDistances = roadDistances;
    _cachedRoadMatrix = roadMatrix;
    _cachedOpenPricesMaxAgeDays = openPricesMaxAgeDays;
    _cachedItemSignature = itemSignature;
    _cachedMobilitySignature = mobilitySignature;
    return next;
  }

  int _itemSignature(Iterable<ListItem> items) => Object.hashAll(
        items.map(
          (item) => Object.hash(
            item.product.id,
            item.product.name,
            item.product.packageAmount,
            item.product.packageUnit,
            item.quantity,
          ),
        ),
      );

  int _mobilitySignature(MobilitySettings settings) => Object.hash(
        settings.startAddress,
        settings.euroPerKm,
        settings.fuelConsumptionLitersPer100Km,
        settings.fuelPricePerLiter,
        settings.timeValuePerHour,
        settings.mode,
        settings.maxStores,
        settings.minExtraStoreSavings,
        settings.additionalStoreCost,
        Object.hashAll(settings.enabledStoreNames),
      );
}
