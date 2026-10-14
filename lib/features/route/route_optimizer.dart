import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/route_plan.dart';
import '../../models/road_route_matrix.dart';
import '../../models/store.dart';
import 'route_price_resolver.dart';
import 'route_price_quality.dart';
import 'route_travel_distance.dart';

class RouteOptimizer {
  RouteOptimizer(
    this.items,
    List<Offer> offers, {
    Map<String, double>? roadDistances,
    this.euroPerKm = 0.22,
    this.maxStores = 3,
    this.minExtraStoreSavings = 0,
    this.additionalStoreCost = 0,
    this.timeValuePerHour = 0,
    this.travelMinutesPerKm = 60 / 45,
    List<String>? enabledStoreNames,
    List<MarketPrice> marketPrices = const <MarketPrice>[],
    this.openPricesMaxAgeDays = 60,
    this.roadMatrix,
    DateTime? now,
  }) : roadDistances = roadDistances ?? const <String, double>{},
       today = now ?? DateTime.now(),
       enabledStoreNames = (enabledStoreNames ?? const <String>[]).toSet(),
       prices = RoutePriceResolver(
         offers,
         marketPrices: marketPrices,
         now: now,
         openPricesMaxAgeDays: openPricesMaxAgeDays,
       );

  final List<ListItem> items;
  final RoutePriceResolver prices;
  final Map<String, double> roadDistances;
  final RoadRouteMatrix? roadMatrix;
  final DateTime today;

  final double euroPerKm;
  final int maxStores;
  final double minExtraStoreSavings;
  final double additionalStoreCost;

  /// User-provided value of time. It affects only route comparison, never the
  /// expected amount paid at checkout.
  final double timeValuePerHour;

  /// Travel-time conversion for the selected mobility mode.
  final double travelMinutesPerKm;
  final Set<String> enabledStoreNames;
  final int openPricesMaxAgeDays;

  // RouteScreen reads the same deterministic result for its summary,
  // recommendation and comparison cards. Keep it for this immutable input
  // snapshot instead of rebuilding every store combination on each read.
  List<RoutePlan>? _alternativesCache;
  RoutePlan? _bestPlanCache;
  var _bestPlanComputed = false;
  RoutePlan? _bestSingleStorePlanCache;
  var _bestSingleStorePlanComputed = false;

  bool isStoreEnabled(Store store) =>
      enabledStoreNames.isEmpty || enabledStoreNames.contains(store.name);

  List<Store> get availableStores =>
      stores.where(isStoreEnabled).toList(growable: false);

  double basketCost(Store store, Iterable<ListItem> selectedItems) {
    return selectedItems.fold<double>(
      0,
      (sum, item) => sum + (prices.quote(store, item)?.total ?? 0),
    );
  }

  OptimizedTravelRoute travelRoute(Iterable<Store> selectedStores) =>
      optimizeTravelRoute(
        selectedStores,
        roadMatrix: roadMatrix,
        fallbackDistances: roadDistances,
      );

  double travelCost(Iterable<Store> selectedStores) =>
      travelRoute(selectedStores).distanceKm * euroPerKm;

  int travelTimeMinutes(Iterable<Store> selectedStores) =>
      _travelMinutesForRoute(travelRoute(selectedStores));

  double timeCost(Iterable<Store> selectedStores) =>
      travelTimeMinutes(selectedStores) / 60 * timeValuePerHour;

  RoutePlan buildPlan(List<Store> selectedStores) {
    final assignments = <Store, List<ListItem>>{};
    final unassigned = <ListItem>[];

    for (final item in items) {
      Store? bestStore;
      var bestScore = double.infinity;

      for (final store in selectedStores) {
        final quote = prices.quote(store, item);
        if (quote == null || quote.isEstimated) continue;
        final score = quote.total + priceUncertaintyReserve(quote, today);
        if (score < bestScore ||
            (score == bestScore &&
                (bestStore == null ||
                    _storeTieKey(store).compareTo(_storeTieKey(bestStore)) <
                        0))) {
          bestScore = score;
          bestStore = store;
        }
      }

      if (bestStore == null) {
        unassigned.add(item);
      } else {
        assignments.putIfAbsent(bestStore, () => []).add(item);
      }
    }

    final basket = assignments.entries.fold<double>(
      0,
      (sum, entry) => sum + basketCost(entry.key, entry.value),
    );
    final uncertaintyReserve = assignments.entries.fold<double>(
      0,
      (sum, entry) =>
          sum +
          entry.value.fold<double>(0, (subtotal, item) {
            final quote = prices.quote(entry.key, item)!;
            return subtotal + priceUncertaintyReserve(quote, today);
          }),
    );
    final optimizedTravel = travelRoute(assignments.keys);
    final travel = optimizedTravel.distanceKm * euroPerKm;
    final travelMinutes = _travelMinutesForRoute(optimizedTravel);
    final timeCost = travelMinutes / 60 * timeValuePerHour;
    final additionalStoreCost =
        (optimizedTravel.stores.length - 1).clamp(0, maxStores).toDouble() *
        this.additionalStoreCost;

    return RoutePlan(
      stores: optimizedTravel.stores,
      assignments: assignments,
      basket: basket,
      travel: travel,
      total: basket + travel,
      unassigned: unassigned,
      uncertaintyReserve: uncertaintyReserve,
      travelMinutes: travelMinutes,
      timeCost: timeCost,
      additionalStoreCost: additionalStoreCost,
    );
  }

  int _travelMinutesForRoute(OptimizedTravelRoute route) {
    final durationMinutes = route.durationMinutes;
    if (durationMinutes != null &&
        durationMinutes.isFinite &&
        durationMinutes >= 0) {
      return durationMinutes.round();
    }
    return _travelMinutesForDistance(route.distanceKm);
  }

  int _travelMinutesForDistance(double distanceKm) {
    if (!distanceKm.isFinite ||
        distanceKm <= 0 ||
        !travelMinutesPerKm.isFinite ||
        travelMinutesPerKm <= 0) {
      return 0;
    }
    return (distanceKm * travelMinutesPerKm).round();
  }

  List<List<Store>> storeCombinations() {
    final source = availableStores;
    final combinations = <List<Store>>[];

    for (final store in source) {
      combinations.add([store]);
    }
    if (maxStores >= 2) {
      for (var i = 0; i < source.length; i++) {
        for (var j = i + 1; j < source.length; j++) {
          combinations.add([source[i], source[j]]);
        }
      }
    }
    if (maxStores >= 3) {
      for (var i = 0; i < source.length; i++) {
        for (var j = i + 1; j < source.length; j++) {
          for (var k = j + 1; k < source.length; k++) {
            combinations.add([source[i], source[j], source[k]]);
          }
        }
      }
    }
    return combinations;
  }

  List<RoutePlan> alternatives() {
    final cached = _alternativesCache;
    if (cached != null) return cached;

    final computed = storeCombinations()
        .map(buildPlan)
        .where((plan) => plan.pricedItemCount > 0)
        .toList()
      ..sort(_comparePlans);
    final stable = List<RoutePlan>.unmodifiable(computed);
    _alternativesCache = stable;
    return stable;
  }

  RoutePlan? bestPlan() {
    if (_bestPlanComputed) return _bestPlanCache;

    final plans = alternatives();
    RoutePlan? recommended;
    if (items.isNotEmpty && plans.isNotEmpty) {
      final bestByCount = <int, RoutePlan>{};
      for (final plan in plans) {
        bestByCount.putIfAbsent(plan.stores.length, () => plan);
      }

      var current =
          bestByCount[1] ??
          bestByCount.values.reduce(
            (a, b) => a.stores.length <= b.stores.length ? a : b,
          );

      for (
        var count = current.stores.length + 1;
        count <= maxStores;
        count++
      ) {
        final candidate = bestByCount[count];
        if (candidate == null) continue;
        // A route that prices more of the requested basket is always preferred.
        // Savings thresholds only decide between routes with equal coverage.
        if (candidate.priceCoverage > current.priceCoverage) {
          current = candidate;
          continue;
        }
        if (candidate.priceCoverage < current.priceCoverage) continue;

        final addedStores = candidate.stores.length - current.stores.length;
        final requiredSavings = minExtraStoreSavings * addedStores;
        if (current.planningScore - candidate.planningScore >
            requiredSavings) {
          current = candidate;
        }
      }
      recommended = current;
    }

    _bestPlanCache = recommended;
    _bestPlanComputed = true;
    return recommended;
  }

  RoutePlan? bestSingleStorePlan() {
    if (_bestSingleStorePlanComputed) return _bestSingleStorePlanCache;

    final plans = alternatives()
        .where((plan) => plan.stores.length == 1)
        .toList(growable: false);
    _bestSingleStorePlanCache = plans.isEmpty ? null : plans.first;
    _bestSingleStorePlanComputed = true;
    return _bestSingleStorePlanCache;
  }

  /// Keeps equal coverage/cost choices reproducible across all callers.
  ///
  /// Coverage remains the primary criterion, followed by the quality-adjusted
  /// planning score and fewer stores. Store names are the final tie-breaker so
  /// a price tie cannot depend on the order in which a source was assembled.
  int _comparePlans(RoutePlan a, RoutePlan b) {
    final coverage = b.priceCoverage.compareTo(a.priceCoverage);
    if (coverage != 0) return coverage;
    final planning = a.planningScore.compareTo(b.planningScore);
    if (planning != 0) return planning;
    final storeCount = a.stores.length.compareTo(b.stores.length);
    if (storeCount != 0) return storeCount;
    final aNames = a.stores.map((store) => store.name).join('|');
    final bNames = b.stores.map((store) => store.name).join('|');
    return aNames.compareTo(bNames);
  }
}

String _storeTieKey(Store store) => [
  store.name,
  store.branchId ?? '',
  store.location,
  store.address,
].map((value) => value.trim().toLowerCase()).join('|');

