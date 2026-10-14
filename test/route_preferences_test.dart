import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/road_route_matrix.dart';
import 'package:sparzamapp/models/store.dart';

final _baselineDate = DateTime(2026, 9, 24);

List<MarketPrice> _baselinePrices() => [
  for (final entry in const <(String, double, double)>[
    ('Lidl', 1.29, 0.89),
    ('EDEKA', 1.39, 1.29),
    ('PENNY', 1.19, 0.79),
    ('ALDI Süd', 1.15, 0.75),
    ('Netto', 1.35, 0.79),
    ('Kaufland', 1.19, 0.72),
  ]) ...[
    MarketPrice(
      productId: 'milch_35',
      storeName: entry.$1,
      price: entry.$2,
      updatedAt: _baselineDate,
    ),
    MarketPrice(
      productId: 'nudeln',
      storeName: entry.$1,
      price: entry.$3,
      updatedAt: _baselineDate,
    ),
  ],
];

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

  Offer stopCostOffer() => Offer(
    id: 'lidl-milk-stop-cost',
    productId: 'milch_35',
    storeName: 'Lidl',
    originalPrice: 1.29,
    offerPrice: 0.10,
    validFrom: DateTime(2026, 9, 25),
    validUntil: DateTime(2026, 9, 26),
    source: 'leaflet',
    proofRef: 'leaflet://lidl-milk-stop-cost',
  );

  RouteOptimizer stopCostOptimizer(
    double additionalStoreCost, {
    List<String> enabledStoreNames = const ['Lidl', 'Kaufland'],
  }) =>
      RouteOptimizer(
        items(),
        [stopCostOffer()],
        now: DateTime(2026, 9, 25),
        euroPerKm: 0,
        maxStores: 2,
        additionalStoreCost: additionalStoreCost,
        enabledStoreNames: enabledStoreNames,
        marketPrices: _baselinePrices(),
      );

  test('maxStores begrenzt erzeugte Routen', () {
    final optimizer = RouteOptimizer(
      items(),
      const [],
      marketPrices: _baselinePrices(),
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
      marketPrices: _baselinePrices(),
      euroPerKm: 0,
      maxStores: 2,
      minExtraStoreSavings: 0.05,
    );
    final relaxed = RouteOptimizer(
      items(),
      const [],
      marketPrices: _baselinePrices(),
      euroPerKm: 0,
      maxStores: 2,
      minExtraStoreSavings: 0.01,
    );

    expect(strict.bestPlan()!.stores.length, 1);
    expect(relaxed.bestPlan()!.stores.length, 2);
  });

  test(
    'zusätzlicher Markt muss seinen Mindestvorteil nach Fahrtkosten erreichen',
    () {
      final strict = RouteOptimizer(
        items(),
        const [],
        marketPrices: _baselinePrices(),
        euroPerKm: 0.22,
        maxStores: 2,
        minExtraStoreSavings: 0.05,
      );

      final recommended = strict.bestPlan()!;
      final alternatives = strict.alternatives();
      final cheaperWithMoreStores = alternatives.where(
        (plan) =>
            plan.stores.length > recommended.stores.length &&
            plan.planningScore < recommended.planningScore,
      );

      for (final candidate in cheaperWithMoreStores) {
        final required =
            strict.minExtraStoreSavings *
            (candidate.stores.length - recommended.stores.length);
        expect(
          recommended.planningScore - candidate.planningScore <= required,
          isTrue,
        );
      }
    },
  );

  test(
    'Angebot rechtfertigt zweiten Markt nur bei Gesamtvorteil inkl Fahrt',
    () {
      final offer = Offer(
        id: 'lidl-milk-special',
        productId: 'milch_35',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.10,
        validFrom: DateTime(2026, 9, 25),
        validUntil: DateTime(2026, 9, 26),
        source: 'leaflet',
        proofRef: 'leaflet://lidl-milk-special',
      );

      final withoutTravel = RouteOptimizer(
        items(),
        [offer],
        marketPrices: _baselinePrices(),
        now: DateTime(2026, 9, 25),
        euroPerKm: 0,
        maxStores: 2,
        enabledStoreNames: const ['Lidl', 'Kaufland'],
      ).bestPlan()!;

      final withTravel = RouteOptimizer(
        items(),
        [offer],
        marketPrices: _baselinePrices(),
        now: DateTime(2026, 9, 25),
        euroPerKm: 0.22,
        maxStores: 2,
        enabledStoreNames: const ['Lidl', 'Kaufland'],
      ).bestPlan()!;

      expect(withoutTravel.stores.map((store) => store.name).toSet(), {
        'Lidl',
        'Kaufland',
      });
      expect(withTravel.stores, hasLength(1));
      expect(withTravel.stores.single.name, 'Lidl');
    },
  );

  test('persönlicher Zeitwert kann zusätzliche Marktfahrten abwerten', () {
    final timeAware = RouteOptimizer(
      items(),
      [
        Offer(
          id: 'lidl-milk-time-value',
          productId: 'milch_35',
          storeName: 'Lidl',
          originalPrice: 1.29,
          offerPrice: 0.10,
          validFrom: DateTime(2026, 9, 25),
          validUntil: DateTime(2026, 9, 26),
          source: 'leaflet',
          proofRef: 'leaflet://lidl-milk-time-value',
        ),
      ],
      now: DateTime(2026, 9, 25),
      euroPerKm: 0,
      maxStores: 2,
      timeValuePerHour: 30,
      travelMinutesPerKm: 60,
      roadDistances: const {'Lidl': 1, 'Kaufland': 10},
      enabledStoreNames: const ['Lidl', 'Kaufland'],
      marketPrices: _baselinePrices(),
    );

    final recommended = timeAware.bestPlan()!;

    expect(recommended.stores, hasLength(1));
    expect(recommended.stores.single.name, 'Lidl');
    expect(recommended.timeCost, greaterThan(0));
    expect(recommended.planningScore, greaterThan(recommended.total));
  });

  test('Kosten je zusätzlichem Markt fließen in den Planungswert ein', () {
    final withoutCost = stopCostOptimizer(0).bestPlan()!;
    final withCost = stopCostOptimizer(0.30).bestPlan()!;

    expect(withoutCost.stores, hasLength(2));
    expect(withoutCost.additionalStoreCost, 0);
    expect(withCost.stores, hasLength(1));
    expect(withCost.stores.single.name, 'Lidl');
    expect(withCost.additionalStoreCost, 0);
  });

  test(
    'Marktstopp-Aufwand erhöht nur den Planungswert einer Mehrmarktroute',
    () {
      final freeOptimizer = stopCostOptimizer(
        0,
        enabledStoreNames: const ['ALDI Süd', 'Kaufland'],
      );
      final pricedOptimizer = stopCostOptimizer(
        0.30,
        enabledStoreNames: const ['ALDI Süd', 'Kaufland'],
      );
      final freePlan = freeOptimizer.buildPlan([
        freeOptimizer.availableStores.firstWhere(
          (store) => store.name == 'ALDI Süd',
        ),
        freeOptimizer.availableStores.firstWhere(
          (store) => store.name == 'Kaufland',
        ),
      ]);
      final pricedPlan = pricedOptimizer.buildPlan([
        pricedOptimizer.availableStores.firstWhere(
          (store) => store.name == 'ALDI Süd',
        ),
        pricedOptimizer.availableStores.firstWhere(
          (store) => store.name == 'Kaufland',
        ),
      ]);

      expect(freePlan.stores, hasLength(2));
      expect(pricedPlan.stores, hasLength(2));
      expect(pricedPlan.total, closeTo(freePlan.total, 0.0001));
      expect(pricedPlan.additionalStoreCost, closeTo(0.30, 0.0001));
      expect(
        pricedPlan.planningScore,
        closeTo(freePlan.planningScore + 0.30, 0.0001),
      );
    },
  );

  test('deaktivierte Märkte werden aus der Optimierung entfernt', () {
    final optimizer = RouteOptimizer(
      items(),
      const [],
      marketPrices: _baselinePrices(),
      euroPerKm: 0,
      enabledStoreNames: const ['Lidl', 'PENNY'],
    );

    expect(optimizer.availableStores.map((store) => store.name), [
      'Lidl',
      'PENNY',
    ]);
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
          productId: 'milch_35',
          storeName: 'Lidl',
          price: 1.29,
          updatedAt: now,
        ),
        MarketPrice(
          productId: 'milch_35',
          storeName: 'EDEKA',
          price: 1.39,
          updatedAt: now,
        ),
        MarketPrice(
          productId: 'nur_edeka',
          storeName: 'EDEKA',
          price: 100,
          updatedAt: now,
        ),
      ],
      now: now,
    );

    final singleStorePlans = optimizer.alternatives().where(
      (plan) => plan.stores.length == 1,
    );
    expect(singleStorePlans.any((plan) => plan.priceCoverage == 0.5), isTrue);
    expect(
      optimizer.alternatives().any((plan) => plan.priceCoverage == 1),
      isTrue,
    );
    expect(optimizer.bestPlan()!.priceCoverage, 1);
  });

  test('Mindestvorteil darf bessere Preisabdeckung nicht blockieren', () {
    const secondItem = Product(
      id: 'coverage_only',
      name: 'Coverage',
      unit: 'Stück',
      group: 'test',
    );
    final now = DateTime(2026, 9, 24);
    final optimizer = RouteOptimizer(
      [ListItem(product: milk), ListItem(product: secondItem)],
      const [],
      euroPerKm: 0,
      maxStores: 2,
      minExtraStoreSavings: 1000,
      enabledStoreNames: const ['Lidl', 'EDEKA'],
      marketPrices: [
        MarketPrice(
          productId: 'coverage_only',
          storeName: 'EDEKA',
          price: 100,
          updatedAt: now,
        ),
        MarketPrice(
          productId: 'milch_35',
          storeName: 'Lidl',
          price: 1.29,
          updatedAt: now,
        ),
        MarketPrice(
          productId: 'milch_35',
          storeName: 'EDEKA',
          price: 1.39,
          updatedAt: now,
        ),
      ],
      now: now,
    );

    expect(optimizer.bestPlan()!.priceCoverage, 1);
    expect(optimizer.bestPlan()!.priceCoverage, 1);
  });

  test('OSRM-Dauer ersetzt die Geschwindigkeitsheuristik für die Zeitkosten', () {
    const product = Product(
      id: 'duration-product',
      name: 'Dauerprodukt',
      unit: 'Stück',
      group: 'test',
    );
    final optimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
      enabledStoreNames: const ['Lidl'],
      euroPerKm: 0,
      timeValuePerHour: 10,
      travelMinutesPerKm: 60,
      marketPrices: [
        MarketPrice(
          productId: product.id,
          storeName: 'Lidl',
          price: 1,
          updatedAt: _baselineDate,
        ),
      ],
      roadMatrix: const RoadRouteMatrix(
        originAddress: 'Start',
        distancesKm: {
          '@origin|Lidl': 1,
          'Lidl|@origin': 1,
        },
        durationsMinutes: {
          '@origin|Lidl': 9,
          'Lidl|@origin': 11,
        },
      ),
    );
    final store = optimizer.availableStores.single;

    expect(optimizer.travelTimeMinutes([store]), 20);
    final plan = optimizer.buildPlan([store]);
    expect(plan.travelMinutes, 20);
    expect(plan.timeCost, closeTo(10 / 3, 0.0001));
  });

  test('gleiche Filialnamen werden über den exakten Branch deterministisch entschieden', () {
    const branchA = Store(
      name: 'Lidl',
      branchId: 'lidl-a',
      location: 'Ort A',
      address: 'A-Straße 1',
      distanceKm: 1,
      prices: <String, double>{},
    );
    const branchB = Store(
      name: 'Lidl',
      branchId: 'lidl-b',
      location: 'Ort B',
      address: 'B-Straße 1',
      distanceKm: 1,
      prices: <String, double>{},
    );
    const product = Product(
      id: 'same-branch-price',
      name: 'Gleiches Produkt',
      unit: 'Stück',
      group: 'test',
    );
    final optimizer = RouteOptimizer(
      [ListItem(product: product)],
      const [],
      storeCatalog: const [branchB, branchA],
      enabledStoreNames: const ['Lidl'],
      maxStores: 1,
      euroPerKm: 0,
      marketPrices: [
        MarketPrice(
          productId: product.id,
          storeName: 'Lidl',
          sourceLocationId: 'lidl-a',
          price: 1,
          updatedAt: _baselineDate,
        ),
        MarketPrice(
          productId: product.id,
          storeName: 'Lidl',
          sourceLocationId: 'lidl-b',
          price: 1,
          updatedAt: _baselineDate,
        ),
      ],
    );

    expect(optimizer.availableStores.map((store) => store.branchId), [
      'lidl-b',
      'lidl-a',
    ]);
    expect(optimizer.bestSingleStorePlan()!.stores.single.branchId, 'lidl-a');
    expect(optimizer.alternatives().first.stores.single.branchId, 'lidl-a');
  });

  test('gleiche Planwerte werden über den Marktnamen entschieden', () {
    const equalProduct = Product(
      id: 'equal-price',
      name: 'Gleichpreis',
      unit: 'Stück',
      group: 'test',
    );
    final optimizer = RouteOptimizer(
      [ListItem(product: equalProduct)],
      const [],
      euroPerKm: 0,
      maxStores: 1,
      enabledStoreNames: const ['Lidl', 'EDEKA'],
      marketPrices: [
        MarketPrice(
          productId: equalProduct.id,
          storeName: 'Lidl',
          price: 1,
          updatedAt: _baselineDate,
        ),
        MarketPrice(
          productId: equalProduct.id,
          storeName: 'EDEKA',
          price: 1,
          updatedAt: _baselineDate,
        ),
      ],
    );

    expect(optimizer.bestSingleStorePlan()!.stores.single.name, 'EDEKA');
    expect(optimizer.alternatives().first.stores.single.name, 'EDEKA');
  });
}

