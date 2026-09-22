import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/offer.dart';
import '../../models/route_plan.dart';
import '../../models/store.dart';
import 'route_price_resolver.dart';

class RouteOptimizer {
  RouteOptimizer(
    this.items,
    List<Offer> offers, {
    Map<String, double>? roadDistances,
    this.euroPerKm = 0.22,
    this.maxStores = 3,
    this.minExtraStoreSavings = 0,
    List<String>? enabledStoreNames,
    List<MarketPrice> marketPrices = const <MarketPrice>[],
  })  : roadDistances = roadDistances ?? const <String, double>{},
        enabledStoreNames =
            (enabledStoreNames ?? const <String>[]).toSet(),
        prices = RoutePriceResolver(offers, marketPrices: marketPrices);

  final List<ListItem> items;
  final RoutePriceResolver prices;
  final Map<String, double> roadDistances;

  final double euroPerKm;
  final int maxStores;
  final double minExtraStoreSavings;
  final Set<String> enabledStoreNames;

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

  double travelCost(Iterable<Store> selectedStores) {
    return selectedStores.fold<double>(
      0,
      (sum, store) => sum +
          ((roadDistances[store.name] ?? store.distanceKm) *
              2 *
              euroPerKm),
    );
  }

  RoutePlan buildPlan(List<Store> selectedStores) {
    final assignments = <Store, List<ListItem>>{};
    final unassigned = <ListItem>[];

    for (final item in items) {
      Store? bestStore;
      var bestPrice = double.infinity;

      for (final store in selectedStores) {
        final quote = prices.quote(store, item);
        if (quote != null && quote.total < bestPrice) {
          bestPrice = quote.total;
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
    final travel = travelCost(assignments.keys);

    return RoutePlan(
      stores: assignments.keys.toList(),
      assignments: assignments,
      basket: basket,
      travel: travel,
      total: basket + travel,
      unassigned: unassigned,
    );
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
        .where((plan) => plan.unassigned.isEmpty)
        .toList()
      ..sort((a, b) {
        final total = a.total.compareTo(b.total);
        return total != 0 ? total : a.stores.length.compareTo(b.stores.length);
      });
  }

  RoutePlan? bestPlan() {
    final plans = alternatives();
    if (items.isEmpty || plans.isEmpty) return null;

    final bestByCount = <int, RoutePlan>{};
    for (final plan in plans) {
      bestByCount.putIfAbsent(plan.stores.length, () => plan);
    }

    var recommended =
        bestByCount[1] ?? bestByCount.values.reduce((a, b) =>
            a.stores.length <= b.stores.length ? a : b);

    for (var count = recommended.stores.length + 1;
        count <= maxStores;
        count++) {
      final candidate = bestByCount[count];
      if (candidate == null) continue;
      final addedStores = candidate.stores.length - recommended.stores.length;
      final requiredSavings = minExtraStoreSavings * addedStores;
      if (recommended.total - candidate.total >= requiredSavings) {
        recommended = candidate;
      }
    }

    return recommended;
  }

  RoutePlan? bestSingleStorePlan() {
    final plans = availableStores
        .map((store) => buildPlan([store]))
        .where((plan) => plan.unassigned.isEmpty)
        .toList()
      ..sort((a, b) => a.total.compareTo(b.total));
    return plans.isEmpty ? null : plans.first;
  }
}
