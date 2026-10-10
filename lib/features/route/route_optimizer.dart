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

  /// User-provided value of time. It affects only route comparison, never the
  /// expected amount paid at checkout.
  final double timeValuePerHour;

  /// Travel-time conversion for the selected mobility mode.
  final double travelMinutesPerKm;
  final Set<String> enabledStoreNames;
  final int openPricesMaxAgeDays;

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
      _travelMinutesForDistance(travelRoute(selectedStores).distanceKm);

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
        if (quote != null &&
            !quote.isEstimated &&
            quote.total + priceUncertaintyReserve(quote, today) < bestScore) {
          bestScore = quote.total + priceUncertaintyReserve(quote, today);
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
    final travelMinutes = _travelMinutesForDistance(optimizedTravel.distanceKm);
    final timeCost = travelMinutes / 60 * timeValuePerHour;

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
    );
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
    return storeCombinations()
        .map(buildPlan)
        .where((plan) => plan.pricedItemCount > 0)
        .toList()
      ..sort(_comparePlans);
  }

  RoutePlan? bestPlan() {
    final plans = alternatives();
    if (items.isEmpty || plans.isEmpty) return null;

    final bestByCount = <int, RoutePlan>{};
    for (final plan in plans) {
      bestByCount.putIfAbsent(plan.stores.length, () => plan);
    }

    var recommended =
        bestByCount[1] ??
        bestByCount.values.reduce(
          (a, b) => a.stores.length <= b.stores.length ? a : b,
        );

    for (
      var count = recommended.stores.length + 1;
      count <= maxStores;
      count++
    ) {
      final candidate = bestByCount[count];
      if (candidate == null) continue;
      // A route that prices more of the requested basket is always preferred.
      // Savings thresholds only decide between routes with equal coverage.
      if (candidate.priceCoverage > recommended.priceCoverage) {
        recommended = candidate;
        continue;
      }
      if (candidate.priceCoverage < recommended.priceCoverage) continue;

      final addedStores = candidate.stores.length - recommended.stores.length;
      final requiredSavings = minExtraStoreSavings * addedStores;
      if (recommended.planningScore - candidate.planningScore >
          requiredSavings) {
        recommended = candidate;
      }
    }

    return recommended;
  }

  RoutePlan? bestSingleStorePlan() {
    final plans =
        availableStores
            .map((store) => buildPlan([store]))
            .where((plan) => plan.pricedItemCount > 0)
            .toList()
          ..sort(_comparePlans);
    return plans.isEmpty ? null : plans.first;
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
