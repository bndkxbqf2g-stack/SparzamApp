import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/route_plan.dart';
import 'package:sparzamapp/models/store.dart';

final _now = DateTime(2026, 9, 30);

const _milk = Product(
  id: 'matrix_milk',
  name: 'Milch',
  unit: '1 l',
  group: 'milch',
);

const _cheese = Product(
  id: 'matrix_cheese',
  name: 'Käse',
  unit: '250 g',
  group: 'milch',
);

const _coffee = Product(
  id: 'matrix_coffee',
  name: 'Kaffee',
  unit: '500 g',
  group: 'kaffee',
);

List<ListItem> _basket() => [
      ListItem(product: _milk),
      ListItem(product: _cheese),
      ListItem(product: _coffee),
    ];

List<MarketPrice> _prices() => [
      for (final entry in const <(String, double, double, double)>[
        ('Lidl', 1, 6, 9),
        ('EDEKA', 4, 1, 8),
        ('ALDI Süd', 3, 5, 2),
      ]) ...[
        MarketPrice(
          productId: _milk.id,
          storeName: entry.$1,
          price: entry.$2,
          updatedAt: _now,
        ),
        MarketPrice(
          productId: _cheese.id,
          storeName: entry.$1,
          price: entry.$3,
          updatedAt: _now,
        ),
        MarketPrice(
          productId: _coffee.id,
          storeName: entry.$1,
          price: entry.$4,
          updatedAt: _now,
        ),
      ],
    ];

void main() {
  test('gleiche Marktpreise bleiben bei vertauschter Store-Reihenfolge stabil', () {
    const first = Store(
      name: 'B-Markt',
      location: 'Ort B',
      branchId: 'branch-b',
      distanceKm: 1,
      prices: <String, double>{},
    );
    const second = Store(
      name: 'A-Markt',
      location: 'Ort A',
      branchId: 'branch-a',
      distanceKm: 1,
      prices: <String, double>{},
    );
    final prices = [
      MarketPrice(
        productId: _milk.id,
        storeName: first.name,
        price: 1,
        updatedAt: _now,
      ),
      MarketPrice(
        productId: _milk.id,
        storeName: second.name,
        price: 1,
        updatedAt: _now,
      ),
    ];
    final optimizer = RouteOptimizer(
      [ListItem(product: _milk)],
      const [],
      now: _now,
      marketPrices: prices,
    );

    final firstOrder = optimizer.buildPlan([first, second]);
    final secondOrder = optimizer.buildPlan([second, first]);

    expect(firstOrder.assignments.keys.single.name, 'A-Markt');
    expect(secondOrder.assignments.keys.single.name, 'A-Markt');
  });

  test('vergleicht denselben Warenkorb gegen ein, zwei und drei Märkte', () {
    final optimizer = RouteOptimizer(
      _basket(),
      const [],
      now: _now,
      euroPerKm: 0.22,
      maxStores: 3,
      minExtraStoreSavings: 0.50,
      enabledStoreNames: const ['Lidl', 'EDEKA', 'ALDI Süd'],
      marketPrices: _prices(),
    );

    final alternatives = optimizer.alternatives();
    final completeByStoreCount = <int, RoutePlan>{
      for (final plan in alternatives.where((plan) => !plan.hasDataGaps))
        plan.stores.length: plan,
    };

    expect(completeByStoreCount.keys, containsAll(<int>[1, 2, 3]));
    expect(completeByStoreCount[1]!.priceCoverage, 1);
    expect(completeByStoreCount[2]!.priceCoverage, 1);
    expect(completeByStoreCount[3]!.priceCoverage, 1);

    final recommended = optimizer.bestPlan()!;
    expect(recommended.stores.map((store) => store.name).toSet(),
        {'Lidl', 'EDEKA', 'ALDI Süd'});
    expect(recommended.basket, closeTo(4, 0.001));
    expect(recommended.travel, greaterThan(0));
    expect(recommended.total, closeTo(5.848, 0.001));
  });

  test('hohe Fahrtkosten ziehen denselben Warenkorb zum Einzelmarkt', () {
    final optimizer = RouteOptimizer(
      _basket(),
      const [],
      now: _now,
      euroPerKm: 5,
      maxStores: 3,
      minExtraStoreSavings: 0.50,
      enabledStoreNames: const ['Lidl', 'EDEKA', 'ALDI Süd'],
      marketPrices: _prices(),
    );

    final recommended = optimizer.bestPlan()!;
    expect(recommended.stores, hasLength(1));
    expect(recommended.stores.single.name, 'ALDI Süd');
    expect(recommended.priceCoverage, 1);
    expect(recommended.hasDataGaps, isFalse);
  });

  test('route alternative identity keeps same-name branches separate', () {
    const branchA = Store(
      name: 'Lidl',
      location: 'Zellingen',
      branchId: 'lidl_zellingen',
      address: 'Am Güßgraben 2',
      distanceKm: 1,
      prices: <String, double>{},
    );
    const branchB = Store(
      name: 'Lidl',
      location: 'Würzburg',
      branchId: 'lidl_wuerzburg',
      address: 'Nürnberger Straße 12',
      distanceKm: 25,
      prices: <String, double>{},
    );
    final item = ListItem(product: _milk);
    final planA = RoutePlan(
      stores: const [branchA],
      assignments: {branchA: [item]},
      basket: 1,
      travel: 1,
      total: 2,
      unassigned: const [],
    );
    final planB = RoutePlan(
      stores: const [branchB],
      assignments: {branchB: [item]},
      basket: 1,
      travel: 25,
      total: 26,
      unassigned: const [],
    );

    expect(routePlanIdentityKey(planA), isNot(routePlanIdentityKey(planB)));
    expect(routeStoreIdentityKey(branchA), contains('lidl_zellingen'));
    expect(routeStoreIdentityKey(branchB), contains('lidl_wuerzburg'));
  });
}
