import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';

void main() {
  const milk = Product(
    id: 'milch_35',
    name: 'Milch',
    unit: '1 l',
    group: 'milch',
  );
  const noodles = Product(
    id: 'nudeln',
    name: 'Nudeln',
    unit: '500 g',
    group: 'nudeln',
  );

  List<ListItem> items() => [
        ListItem(product: milk),
        ListItem(product: noodles),
      ];

  test('maxStores begrenzt erzeugte Routen', () {
    final optimizer = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0,
      maxStores: 1,
    );

    expect(
      optimizer.storeCombinations().every((combo) => combo.length == 1),
      isTrue,
    );
    expect(optimizer.bestPlan()!.stores.length, 1);
  });

  test('Mindestvorteil verhindert unnötigen zweiten Markt', () {
    final strict = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0,
      maxStores: 2,
      minExtraStoreSavings: 0.05,
    );
    final relaxed = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0,
      maxStores: 2,
      minExtraStoreSavings: 0.01,
    );

    expect(strict.bestPlan()!.stores.length, 1);
    expect(relaxed.bestPlan()!.stores.length, 2);
  });

  test('zusätzlicher Markt muss seinen Mindestvorteil nach Fahrtkosten erreichen', () {
    final strict = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0.22,
      maxStores: 2,
      minExtraStoreSavings: 0.05,
    );

    final recommended = strict.bestPlan()!;
    final alternatives = strict.alternatives();
    final cheaperWithMoreStores = alternatives.where(
      (plan) => plan.stores.length > recommended.stores.length &&
          plan.planningScore < recommended.planningScore,
    );

    for (final candidate in cheaperWithMoreStores) {
      final required = strict.minExtraStoreSavings *
          (candidate.stores.length - recommended.stores.length);
      expect(
        recommended.planningScore - candidate.planningScore <= required,
        isTrue,
      );
    }
  });

  test('Angebot rechtfertigt zweiten Markt nur bei Gesamtvorteil inkl Fahrt', () {
    final offer = Offer(
      id: 'lidl-milk-special',
      productId: 'milch_35',
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.10,
      validFrom: DateTime(2026, 9, 25),
      validUntil: DateTime(2026, 9, 26),
      source: 'leaflet',
    );

    final withoutTravel = RouteOptimizer(
      items(),
      [offer],
      now: DateTime(2026, 9, 25),
      euroPerKm: 0,
      maxStores: 2,
      enabledStoreNames: const ['Lidl', 'Kaufland'],
    ).bestPlan()!;

    final withTravel = RouteOptimizer(
      items(),
      [offer],
      now: DateTime(2026, 9, 25),
      euroPerKm: 0.22,
      maxStores: 2,
      enabledStoreNames: const ['Lidl', 'Kaufland'],
    ).bestPlan()!;

    expect(withoutTravel.stores.map((store) => store.name).toSet(),
        {'Lidl', 'Kaufland'});
    expect(withTravel.stores, hasLength(1));
    expect(withTravel.stores.single.name, 'Lidl');
  });

  test('deaktivierte Märkte werden aus der Optimierung entfernt', () {
    final optimizer = RouteOptimizer(
      items(),
      const [],
      euroPerKm: 0,
      enabledStoreNames: const ['Lidl', 'PENNY'],
    );

    expect(
      optimizer.availableStores.map((store) => store.name),
      ['Lidl', 'PENNY'],
    );
    expect(
      optimizer.alternatives().every(
            (plan) => plan.stores.every(
              (store) => const ['Lidl', 'PENNY'].contains(store.name),
            ),
          ),
      isTrue,
    );
  });

  test('vollständiger Warenkorb schlägt billigere unvollständige Route', () {
    const secondItem = Product(
      id: 'nur_edeka',
      name: 'Nur EDEKA',
      unit: 'Stück',
      group: 'test',
    );
    final now = DateTime(2026, 9, 24);
    final optimizer = RouteOptimizer(
      [ListItem(product: milk), ListItem(product: secondItem)],
      const [],
      euroPerKm: 0,
      maxStores: 2,
      enabledStoreNames: const ['Lidl', 'EDEKA'],
      marketPrices: [
        MarketPrice(
          productId: 'nur_edeka',
          storeName: 'EDEKA',
          price: 100,
          updatedAt: now,
        ),
      ],
      now: now,
    );

    final singleStorePlans = optimizer.alternatives().where((plan) => plan.stores.length == 1);
    expect(singleStorePlans.any((plan) => plan.priceCoverage == 0.5), isTrue);
    expect(optimizer.alternatives().any((plan) => plan.priceCoverage == 1), isTrue);
    expect(optimizer.bestPlan()!.priceCoverage, 1);
  });

  test('Mindestvorteil darf bessere Preisabdeckung nicht blockieren', () {
    const secondItem = Product(id: 'coverage_only', name: 'Coverage', unit: 'Stück', group: 'test');
    final now = DateTime(2026, 9, 24);
    final optimizer = RouteOptimizer(
      [ListItem(product: milk), ListItem(product: secondItem)],
      const [],
      euroPerKm: 0,
      maxStores: 2,
      minExtraStoreSavings: 1000,
      enabledStoreNames: const ['Lidl', 'EDEKA'],
      marketPrices: [
        MarketPrice(productId: 'coverage_only', storeName: 'EDEKA', price: 100, updatedAt: now),
        MarketPrice(productId: 'milch_35', storeName: 'Lidl', price: 1.29, updatedAt: now),
        MarketPrice(productId: 'milch_35', storeName: 'EDEKA', price: 1.39, updatedAt: now),
      ],
      now: now,
    );

    expect(optimizer.bestPlan()!.priceCoverage, 1);
    expect(optimizer.bestPlan()!.priceCoverage, 1);
  });
}
