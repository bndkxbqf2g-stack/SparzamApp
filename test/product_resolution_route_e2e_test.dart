import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/shopping_list/planning_market_prices.dart';
import 'package:sparzamapp/features/shopping_list/receipt_family_market_prices.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_observation.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';
import 'package:sparzamapp/services/price_observation_store.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/features/offers/prospect_regular_price_persistence.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';

void main() {
  test('confirmed receipt product flows from identity to route calculation', () {
    const product = Product(
      id: 'confirmed-schmand-200',
      name: 'Schmand 200 g',
      unit: '200 g',
      group: 'milchprodukte',
      packageAmount: 200,
      packageUnit: 'g',
    );
    final item = ListItem(product: product);
    final now = DateTime(2026, 9, 25);
    final familyPrices = receiptFamilyMarketPrices(
      items: [item],
      now: now,
      observations: [
        ReceiptObservation(
          id: 'confirmed-schmand-receipt',
          receiptFingerprint: 'confirmed-schmand-receipt',
          rowLine: 4,
          rawLabel: 'OCR 4 ??',
          familyKey: '',
          storeName: 'Kaufland',
          observedAt: now,
          totalPrice: 0.99,
          quantity: 200,
          quantityUnit: 'g',
          unitPrice: null,
          discounted: false,
          productId: product.id,
          identityConfirmed: true,
        ),
      ],
    );
    final planning = planningMarketPrices(
      exactPrices: const [],
      familyPrices: familyPrices,
      now: now,
    );
    final optimizer = RouteOptimizer(
      [item],
      const [],
      marketPrices: planning,
      enabledStoreNames: const ['Kaufland'],
      maxStores: 1,
      now: now,
      euroPerKm: 0,
    );

    final route = optimizer.bestSingleStorePlan();
    expect(familyPrices.single.productId, product.id);
    expect(planning.single.price, closeTo(0.99, 0.0001));
    expect(route, isNotNull);
    expect(route!.unassigned, isEmpty);
    expect(route.basket, closeTo(0.99, 0.0001));
  });

  test('compatible receipt observations reach route optimization', () {
    const paprika = Product(
      id: 'shopping-paprika',
      name: 'Paprika',
      unit: 'Stück',
      group: 'gemuese',
    );
    final item = ListItem(product: paprika);
    final now = DateTime(2026, 9, 25);
    final familyPrices = receiptFamilyMarketPrices(
      items: [item],
      now: now,
      observations: [
        for (final entry in [
          ('Lidl', 'Paprika Mix 500g', 0.99),
          ('EDEKA', 'rote Paprika', 1.29),
          ('Kaufland', 'Pringles Paprika', 0.49),
        ])
          ReceiptObservation(
            id: 'paprika-${entry.$1}',
            receiptFingerprint: 'receipt-${entry.$1}',
            rowLine: 1,
            rawLabel: entry.$2,
            familyKey: '',
            storeName: entry.$1,
            observedAt: now,
            totalPrice: entry.$3,
            quantity: null,
            quantityUnit: '',
            unitPrice: null,
            discounted: false,
          ),
      ],
    );
    final planning = planningMarketPrices(exactPrices: const [], familyPrices: familyPrices);
    final optimizer = RouteOptimizer(
      [item],
      const [],
      marketPrices: planning,
      enabledStoreNames: const ['Lidl', 'EDEKA', 'Kaufland'],
      maxStores: 1,
      now: now,
    );

    final route = optimizer.bestSingleStorePlan();
    expect(familyPrices.map((price) => price.storeName).toSet(), {'Lidl', 'EDEKA'});
    expect(route, isNotNull);
    expect(route!.pricedItemCount, 1);
    expect(route.unassigned, isEmpty);
    expect(route.stores.single.name, 'Lidl');
  });
  test(
    'persisted regular prospect price flows through projection and exact-branch routing',
    () async {
      final now = DateTime(2026, 10, 15, 12);
      const coffee = Product(
        id: 'route-prospect-coffee-500',
        name: 'Jacobs Kaffee Crema 500 g',
        unit: '500 g',
        group: 'Kaffee & Snacks',
        packageAmount: 500,
        packageUnit: 'g',
      );
      final record = OfferImportRecord(
        sourceId: 'route-prospect-coffee',
        productLabel: coffee.name,
        storeName: 'Lidl',
        originalPrice: 7.99,
        offerPrice: 4.99,
        validFrom: DateTime(2026, 10, 12),
        validUntil: DateTime(2026, 10, 17),
        source: 'retailerWebsite',
        sourceAdapter: 'KaufDA',
        branchId: 'lidl-wuerzburg',
        location: 'Würzburg',
        proofRef: 'https://www.kaufda.de/prospekt/route-prospect-coffee',
        capturedAt: now,
      );
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
      var raw = <String>[];
      final store = PriceObservationStore(
        readRaw: () async => List<String>.of(raw),
        writeRaw: (values) async => raw = List<String>.of(values),
      );

      final persisted = await persistCurrentProspectRegularPrices(
        store: store,
        records: [record],
        catalogProducts: const [coffee],
        observedAt: now,
        now: now,
        refreshedStoreScopes: const [
          ProspectRefreshScope(
            storeName: 'Lidl',
            branchId: 'lidl-wuerzburg',
          ),
        ],
      );
      final projected = marketPricesFromObservations(
        persisted.stored,
        products: const [coffee],
        now: now,
      );
      final planning = planningMarketPrices(
        exactPrices: projected,
        familyPrices: const [],
        now: now,
      );
      const selectedBranch = Store(
        name: 'Lidl',
        branchId: 'lidl-wuerzburg',
        location: 'Würzburg',
        distanceKm: 1,
        prices: <String, double>{},
      );
      final route = RouteOptimizer(
        [ListItem(product: coffee)],
        const [],
        storeCatalog: const [selectedBranch],
        enabledStoreNames: const ['Lidl'],
        marketPrices: planning,
        maxStores: 1,
        euroPerKm: 0,
        now: now,
      ).bestSingleStorePlan();

      expect(persisted.learned, hasLength(1));
      expect(persisted.learned.single.kind, PriceObservationKind.regular);
      expect(persisted.learned.single.price, 7.99);
      expect(persisted.learned.single.price, isNot(4.99));
      expect(persisted.stored.single.locationId, selectedBranch.branchId);
      expect(projected, hasLength(1));
      expect(projected.single.source, MarketPriceSource.prospect);
      expect(projected.single.sourceLocationId, selectedBranch.branchId);
      expect(planning.single.price, 7.99);
      expect(route, isNotNull);
      expect(route!.unassigned, isEmpty);
      expect(route.stores.single.branchId, selectedBranch.branchId);
      expect(route.basket, closeTo(7.99, 0.0001));
    },
  );

  test('a price from another branch cannot enter the selected route', () {
    const coffee = Product(
      id: 'route-branch-coffee',
      name: 'Jacobs Kaffee Crema 500 g',
      unit: '500 g',
      group: 'Kaffee & Snacks',
      packageAmount: 500,
      packageUnit: 'g',
    );
    const selectedBranch = Store(
      name: 'Lidl',
      branchId: 'lidl-wuerzburg',
      location: 'Würzburg',
      distanceKm: 1,
      prices: <String, double>{},
    );
    final projected = marketPricesFromObservations(
      [
        PriceObservation(
          id: 'wrong-branch',
          productId: coffee.id,
          storeName: 'Lidl',
          locationId: 'lidl-zellingen',
          region: 'Zellingen',
          price: 0.99,
          quantity: 500,
          unit: 'g',
          observedAt: DateTime(2026, 10, 15),
          source: PriceObservationSource.leaflet,
          kind: PriceObservationKind.regular,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'leaflet:lidl:route-branch',
        ),
      ],
      products: const [coffee],
      now: DateTime(2026, 10, 15),
    );
    final route = RouteOptimizer(
      [ListItem(product: coffee)],
      const [],
      storeCatalog: const [selectedBranch],
      enabledStoreNames: const ['Lidl'],
      marketPrices: planningMarketPrices(
        exactPrices: projected,
        familyPrices: const [],
        now: DateTime(2026, 10, 15),
      ),
      maxStores: 1,
      euroPerKm: 0,
      now: DateTime(2026, 10, 15),
    ).bestSingleStorePlan();

    expect(projected.single.sourceLocationId, 'lidl-zellingen');
    expect(route, isNull);
  });

}
