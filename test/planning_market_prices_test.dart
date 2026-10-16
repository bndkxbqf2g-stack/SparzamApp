import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/planning_market_prices.dart';
import 'package:sparzamapp/features/shopping_list/shopping_price_quotes.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';

void main() {
  for (final name in ['Schmand', 'Joghurt']) {
    test('$name uses the same exact price in list and route', () {
      final product = Product(id: name, name: name, unit: 'Stück', group: name);
      final item = ListItem(product: product);
      final prices = planningMarketPrices(
        familyPrices: [
          MarketPrice(productId: name, storeName: 'Lidl', price: 0.69,
              updatedAt: DateTime(2026, 9, 24), source: MarketPriceSource.receipt),
        ],
        exactPrices: [
          MarketPrice(productId: name, storeName: 'Lidl', price: 0.79,
              updatedAt: DateTime(2026, 9, 23)),
        ],
      );
      const store = Store(name: 'Lidl', location: 'Ort', distanceKm: 1,
          prices: <String, double>{});
      expect(shoppingQuotes(item, prices: prices, offers: []).single.unitPrice,
          0.79);
      expect(RoutePriceResolver([], marketPrices: prices).quote(store, item)!.total,
          0.79);
    });
  }

  test('planning keeps quality ranking instead of blindly taking newest exact price', () {
    final now = DateTime(2026, 9, 25);
    final prices = planningMarketPrices(
      exactPrices: [
        MarketPrice(
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.79,
          updatedAt: DateTime(2026, 8, 20),
          source: MarketPriceSource.manual,
        ),
        MarketPrice(
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.89,
          updatedAt: DateTime(2026, 9, 25),
          source: MarketPriceSource.openPrices,
        ),
      ],
      familyPrices: const [],
      now: now,
    );

    expect(prices, hasLength(1));
    expect(prices.single.price, 0.79);

    const store = Store(
      name: 'Lidl',
      location: 'Ort',
      distanceKm: 1,
      prices: <String, double>{},
    );
    const product = Product(
      id: 'schmand',
      name: 'Schmand',
      unit: 'Stück',
      group: 'schmand',
    );
    final quote = RoutePriceResolver(
      const [],
      marketPrices: prices,
      now: now,
    ).quote(store, ListItem(product: product));

    expect(quote, isNotNull);
    expect(quote!.total, 0.79);
  });

  test('planning keeps current prospect regular prices per exact branch', () {
    final prices = planningMarketPrices(
      exactPrices: [
        MarketPrice(
          productId: 'milk',
          storeName: 'Lidl',
          price: 1.29,
          updatedAt: DateTime(2026, 10, 13),
          source: MarketPriceSource.prospect,
          sourceLocationId: 'lidl-thuengersheim',
          sourceLocationName: 'Lidl Thüngersheim',
          kind: PriceObservationKind.regular,
          quantity: 1000,
          unit: 'ml',
          unitPrice: 1.29,
        ),
        MarketPrice(
          productId: 'milk',
          storeName: 'Lidl',
          price: 1.19,
          updatedAt: DateTime(2026, 10, 13),
          source: MarketPriceSource.prospect,
          sourceLocationId: 'lidl-wuerzburg',
          sourceLocationName: 'Lidl Würzburg',
          kind: PriceObservationKind.regular,
          quantity: 1000,
          unit: 'ml',
          unitPrice: 1.19,
        ),
      ],
      familyPrices: const [],
      now: DateTime(2026, 10, 13),
    );

    expect(prices, hasLength(2));
    expect(prices.every((price) => price.source == MarketPriceSource.prospect), isTrue);
    expect(prices.map((price) => price.sourceLocationId), containsAll([
      'lidl-thuengersheim',
      'lidl-wuerzburg',
    ]));
  });

  test('planning excludes a legacy prospect offer market price', () {
    final offerPrice = MarketPrice(
      productId: 'milk',
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 10, 13),
      source: MarketPriceSource.prospect,
      kind: PriceObservationKind.offer,
      discounted: true,
      sourceLocationId: 'lidl-zellingen',
    );

    expect(
      planningMarketPrices(
        exactPrices: [offerPrice],
        familyPrices: const [],
        now: DateTime(2026, 10, 13),
      ),
      isEmpty,
    );
  });
  test('planning applies the configured Open Prices age', () {
    final prices = planningMarketPrices(
      exactPrices: [
        MarketPrice(
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.89,
          updatedAt: DateTime(2026, 9, 20),
          source: MarketPriceSource.openPrices,
        ),
      ],
      familyPrices: const [],
      now: DateTime(2026, 9, 24),
      openPricesMaxAgeDays: 3,
    );

    expect(prices, isEmpty);
  });

  test('planning preserves separate exact branch observations', () {
    final prices = planningMarketPrices(
      exactPrices: [
        MarketPrice(
          productId: 'milk',
          storeName: 'Lidl',
          price: 0.79,
          updatedAt: DateTime(2026, 10, 12),
          sourceLocationId: 'lidl-zellingen',
        ),
        MarketPrice(
          productId: 'milk',
          storeName: 'Lidl',
          price: 0.49,
          updatedAt: DateTime(2026, 10, 12),
          sourceLocationId: 'lidl-wuerzburg',
        ),
      ],
      familyPrices: const [],
      now: DateTime(2026, 10, 12),
    );

    expect(prices, hasLength(2));
    expect(prices.map((price) => price.sourceLocationId), containsAll([
      'lidl-zellingen',
      'lidl-wuerzburg',
    ]));
  });

  test('planning and route selection break exact ties independently of input order', () {
    final first = MarketPrice(
      productId: 'milk',
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 10, 12),
      sourceAdapter: 'z-source',
    );
    final second = MarketPrice(
      productId: 'milk',
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 10, 12),
      sourceAdapter: 'a-source',
    );
    const store = Store(
      name: 'Lidl',
      location: 'Ort',
      distanceKm: 1,
      prices: <String, double>{},
    );
    const product = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );

    for (final order in [
      [first, second],
      [second, first],
    ]) {
      final prices = planningMarketPrices(
        exactPrices: order,
        familyPrices: const [],
        now: DateTime(2026, 10, 12),
      );
      expect(prices.single.sourceAdapter, 'a-source');
      final quote = RoutePriceResolver(
        const [],
        marketPrices: order,
        now: DateTime(2026, 10, 12),
      ).quote(store, ListItem(product: product));
      expect(quote?.observation?.sourceAdapter, 'a-source');
    }
  });

  test('current prospect projection prefers the newest correction for one proof', () {
    final oldObservation = PriceObservation(
      id: 'prospect-old',
      productId: 'milk',
      storeName: 'Lidl',
      price: 1.29,
      observedAt: DateTime(2026, 10, 12, 8),
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.regular,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      locationId: 'lidl-zellingen',
      quantity: 1000,
      unit: 'ml',
      unitPrice: 1.29,
      proofRef: 'https://example.test/lidl/milk',
    );
    final correctedObservation = PriceObservation(
      id: 'prospect-corrected',
      productId: 'milk',
      storeName: 'Lidl',
      price: 1.49,
      observedAt: DateTime(2026, 10, 13, 8),
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.regular,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      locationId: 'lidl-zellingen',
      quantity: 1000,
      unit: 'ml',
      unitPrice: 1.49,
      proofRef: 'https://example.test/lidl/milk',
    );

    final prices = marketPricesFromObservations(
      [oldObservation, correctedObservation],
      now: DateTime(2026, 10, 13),
    );

    expect(prices, hasLength(1));
    expect(prices.single.price, 1.49);
    expect(prices.single.updatedAt, correctedObservation.observedAt);
  });

  test(
    'current prospect projection replaces an older claim when proof changes',
    () {
      final older = PriceObservation(
        id: 'prospect-old-proof',
        productId: 'milk',
        storeName: 'Lidl',
        price: 1.29,
        observedAt: DateTime(2026, 10, 12, 8),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.regular,
        validFrom: DateTime(2026, 10, 12),
        validUntil: DateTime(2026, 10, 17),
        locationId: 'lidl-zellingen',
        quantity: 1000,
        unit: 'ml',
        unitPrice: 1.29,
        proofRef: 'https://example.test/lidl/old-page',
      );
      final refreshed = PriceObservation(
        id: 'prospect-new-proof',
        productId: 'milk',
        storeName: 'Lidl',
        price: 1.49,
        observedAt: DateTime(2026, 10, 13, 8),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.regular,
        validFrom: DateTime(2026, 10, 12),
        validUntil: DateTime(2026, 10, 17),
        locationId: 'lidl-zellingen',
        quantity: 1000,
        unit: 'ml',
        unitPrice: 1.49,
        proofRef: 'https://example.test/lidl/new-page',
      );

      final projected = marketPricesFromObservations(
        [older, refreshed],
        now: DateTime(2026, 10, 13),
      );

      expect(projected, hasLength(1));
      expect(projected.single.price, 1.49);
      expect(projected.single.proofRef, refreshed.proofRef);
    },
  );
}
