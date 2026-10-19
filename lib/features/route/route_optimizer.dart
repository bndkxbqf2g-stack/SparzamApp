import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/mobility_settings.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/route_plan.dart';
import '../../models/road_route_matrix.dart';
import '../../models/store.dart';
import 'route_price_resolver.dart';
import '../../services/store_identity.dart';
import 'route_price_quality.dart';
import 'route_travel_distance.dart';

class RouteOptimizer {
  RouteOptimizer(
    this.items,
    List<Offer> offers, {
    Map<String, double>? roadDistances,
    double euroPerKm = 0.22,
    int maxStores = 3,
    double minExtraStoreSavings = 0,
    double additionalStoreCost = 0,
    double timeValuePerHour = 0,
    double travelMinutesPerKm = 60 / 45,
    List<String>? enabledStoreNames,
    List<Store>? storeCatalog,
    List<MarketPrice> marketPrices = const <MarketPrice>[],
    int openPricesMaxAgeDays = 60,
    this.roadMatrix,
    DateTime? now,
  }) : roadDistances = roadDistances ?? const <String, double>{},
       euroPerKm = _finiteNonNegative(euroPerKm, 0.22),
       maxStores = maxStores.clamp(1, maximumSupportedRouteStores).toInt(),
       minExtraStoreSavings = _finiteNonNegative(minExtraStoreSavings, 0),
       additionalStoreCost = _finiteNonNegative(additionalStoreCost, 0),
       timeValuePerHour = _finiteNonNegative(timeValuePerHour, 0),
       travelMinutesPerKm = _finiteNonNegative(travelMinutesPerKm, 60 / 45),
       openPricesMaxAgeDays = openPricesMaxAgeDays < 0 ? 60 : openPricesMaxAgeDays,
       storeCatalog = storeCatalog ?? stores,
       today = now ?? DateTime.now(),
       enabledStoreNames = (enabledStoreNames ?? const <String>[]).toSet(),
       prices = RoutePriceResolver(
         offers,
         marketPrices: marketPrices,
         now: now,
         openPricesMaxAgeDays: openPricesMaxAgeDays < 0 ? 60 : openPricesMaxAgeDays,
       );

  final List<ListItem> items;
  final RoutePriceResolver prices;
  /// Exact branch catalog used for this calculation. The default remains the
  /// configured project-market list; callers may provide a branch-resolved
  /// snapshot without changing the global store registry.
  final List<Store> storeCatalog;
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

  // Route alternatives call the same travel calculation repeatedly. Keep the
  // immutable result per exact-store set so complete road matrices do not
  // enumerate the same permutations again.
  final Map<String, OptimizedTravelRoute> _travelRouteCache =
      <String, OptimizedTravelRoute>{};

  bool isStoreEnabled(Store store) =>
      enabledStoreNames.isEmpty ||
      enabledStoreNames.any((name) => sameStoreLabel(name, store.name));

  /// Returns enabled exact branches once, preserving catalog order.
  ///
  /// Feed merges can contain the same branch more than once (for example after
  /// a retailer label or source refresh change). Treating those duplicate rows
  /// as separate route stops inflates combination counts and can make a route
  /// appear to use the same market twice.
  List<Store> get availableStores {
    final seen = <String>{};
    final result = <Store>[];
    for (final store in storeCatalog) {
      if (!isStoreEnabled(store)) continue;
      if (seen.add(routeStoreIdentityKey(store))) result.add(store);
    }
    return List<Store>.unmodifiable(result);
  }

  double basketCost(Store store, Iterable<ListItem> selectedItems) {
    return selectedItems.fold<double>(
      0,
      (sum, item) => sum + (prices.quote(store, item)?.total ?? 0),
    );
  }

  OptimizedTravelRoute travelRoute(Iterable<Store> selectedStores) {
    final stores = selectedStores.toList(growable: false);
    // The route solver evaluates the optimal order itself, so the selected
    // store set is the cache identity independent of caller order.
    final cacheParts = stores.map(_travelRouteStoreKey).toList()..sort();
    final key = cacheParts.join('\u001e');
    final cached = _travelRouteCache[key];
    if (cached != null) return cached;

    final computed = optimizeTravelRoute(
      stores,
      roadMatrix: roadMatrix,
      fallbackDistances: roadDistances,
      euroPerKm: euroPerKm,
      timeValuePerHour: timeValuePerHour,
    );
    _travelRouteCache[key] = computed;
    return computed;
  }

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
                    routeStoreIdentityKey(store).compareTo(routeStoreIdentityKey(bestStore)) <
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

  /// Returns every non-empty market combination up to [maxStores].
  ///
  /// The previous implementation stopped at three nested loops, which made
  /// the optimizer silently ignore configured markets once a user selected
  /// four or more stops. The recursive generator keeps the existing
  /// deterministic source order while supporting the complete seven-market
  /// project catalog without introducing an external solver.
  List<List<Store>> storeCombinations() {
    final source = availableStores;
    if (source.isEmpty) return const <List<Store>>[];

    final limit = maxStores.clamp(1, source.length).toInt();
    final combinations = <List<Store>>[];

    void visit(int start, List<Store> selected) {
      if (selected.isNotEmpty) {
        combinations.add(List<Store>.of(selected));
      }
      if (selected.length == limit) return;

      for (var index = start; index < source.length; index++) {
        selected.add(source[index]);
        visit(index + 1, selected);
        selected.removeLast();
      }
    }

    visit(0, <Store>[]);
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
        final planningBenefit =
            current.planningScore - candidate.planningScore;
        // A configured positive threshold is inclusive: exactly the stated
        // minimum is enough to justify the additional stops. With no threshold
        // configured, retain the fewer-store tie-breaker and require a real
        // improvement instead of accepting an equal plan.
        final meetsMinimum = requiredSavings > 0
            ? planningBenefit >= requiredSavings
            : planningBenefit > 0;
        if (meetsMinimum) current = candidate;
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
  /// The branch ID and address are part of the final key so two same-named
  /// branches remain deterministic and cannot be silently interchanged.
  int _comparePlans(RoutePlan a, RoutePlan b) {
    final coverage = b.priceCoverage.compareTo(a.priceCoverage);
    if (coverage != 0) return coverage;
    final planning = a.planningScore.compareTo(b.planningScore);
    if (planning != 0) return planning;
    final storeCount = a.stores.length.compareTo(b.stores.length);
    if (storeCount != 0) return storeCount;
    final aKey = a.stores.map(routeStoreIdentityKey).join('|');
    final bKey = b.stores.map(routeStoreIdentityKey).join('|');
    return aKey.compareTo(bKey);
  }
}

String _travelRouteStoreKey(Store store) {
  final identity = routeStoreIdentityKey(store);
  final distance = store.distanceKm.toString();
  return '${identity.length}:$identity:${distance.length}:$distance';
}

double _finiteNonNegative(double value, double fallback) =>
    value.isFinite && value >= 0 ? value : fallback;


