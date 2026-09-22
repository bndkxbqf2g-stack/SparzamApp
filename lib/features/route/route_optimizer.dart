import '../../data/stores.dart';
import '../../models/list_item.dart';
import '../../models/offer.dart';
import '../../models/route_plan.dart';
import '../../models/store.dart';
import 'route_price_resolver.dart';

class RouteOptimizer {
  RouteOptimizer(this.items, List<Offer> offers)
      : prices = RoutePriceResolver(offers);

  final List<ListItem> items;
  final RoutePriceResolver prices;

  static const double euroPerKmRoundTrip = 0.22;

  double basketCost(Store store, Iterable<ListItem> selectedItems) {
    return selectedItems.fold<double>(
      0,
      (sum, item) => sum + (prices.quote(store, item)?.total ?? 0),
    );
  }

  double travelCost(Iterable<Store> selectedStores) {
    return selectedStores.fold<double>(
      0,
      (sum, store) => sum + (store.distanceKm * 2 * euroPerKmRoundTrip),
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
    final combinations = <List<Store>>[];

    for (final store in stores) {
      combinations.add([store]);
    }
    for (var i = 0; i < stores.length; i++) {
      for (var j = i + 1; j < stores.length; j++) {
        combinations.add([stores[i], stores[j]]);
      }
    }
    for (var i = 0; i < stores.length; i++) {
      for (var j = i + 1; j < stores.length; j++) {
        for (var k = j + 1; k < stores.length; k++) {
          combinations.add([stores[i], stores[j], stores[k]]);
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
    return items.isEmpty || plans.isEmpty ? null : plans.first;
  }

  RoutePlan? bestSingleStorePlan() {
    final plans = stores
        .map((store) => buildPlan([store]))
        .where((plan) => plan.unassigned.isEmpty)
        .toList()
      ..sort((a, b) => a.total.compareTo(b.total));
    return plans.isEmpty ? null : plans.first;
  }
}
