import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_regular_price_persistence.dart';
import 'package:sparzamapp/features/offers/prospect_price_learning.dart';
import 'package:sparzamapp/features/shopping_list/shopping_price_quotes.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';
import 'package:sparzamapp/services/price_observation_store.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);
  const coffee = Product(
    id: 'coffee-500',
    name: 'Jacobs Kaffee Crema 500 g',
    unit: '500 g',
    group: 'kaffee',
  );
  final now = DateTime(2026, 10, 12, 12);
  final current = OfferImportRecord(
    sourceId: 'kaufda-coffee-current',
    productLabel: coffee.name,
    storeName: 'Lidl',
    originalPrice: 7.99,
    offerPrice: 4.99,
    validFrom: DateTime(2026, 10, 10),
    validUntil: DateTime(2026, 10, 17),
    source: 'retailerWebsite',
    sourceAdapter: 'kaufda',
    branchId: 'lidl-branch-1',
    proofRef: 'https://example.test/kaufda/coffee',
    capturedAt: now,
  );

  PriceObservationStore memoryStore() {
    var raw = <String>[];
    return PriceObservationStore(
      readRaw: () async => raw,
      writeRaw: (values) async => raw = [...values],
    );
  }

  test('stores only the current regular prospect price and projects it', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(result.learned, hasLength(1));
    expect(result.learned.single.kind, PriceObservationKind.regular);
    expect(result.learned.single.price, 7.99);
    expect(result.learned.single.storeName, 'Lidl');
    expect(result.learned.single.locationId, 'lidl-branch-1');
    expect(result.learned.single.proofRef, current.proofRef);
    expect(result.stored, hasLength(1));
    expect(result.stored.single.kind, PriceObservationKind.regular);
    expect(result.stored.single.discounted, isFalse);

    final projected = marketPricesFromObservations(
      result.stored,
      products: const [coffee],
      now: now,
    );
    expect(projected, hasLength(1));
    expect(projected.single.source, MarketPriceSource.prospect);
    expect(projected.single.price, 7.99);
    expect(projected.single.kind, PriceObservationKind.regular);
  });

  test('projects the persisted regular price into the shopping-list quote', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current.copyWith(branchId: 'lidl_zellingen')],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    final projected = marketPricesFromObservations(
      result.stored,
      products: const [coffee],
      now: now,
    );
    final quotes = shoppingQuotes(
      ListItem(product: coffee),
      prices: projected,
      offers: const [],
      enabledStores: const ['Lidl'],
      now: now,
    );

    expect(quotes, hasLength(1));
    expect(quotes.single.storeName, 'Lidl');
    expect(quotes.single.unitPrice, 7.99);
    expect(quotes.single.isRegularProspectPrice, isTrue);
    expect(quotes.single.kind, ShoppingQuoteKind.prospect);
  });

  test('does not persist an equal original amount as regular history', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [
        OfferImportRecord(
          sourceId: 'equal-amount',
          productLabel: coffee.name,
          storeName: 'Lidl',
          originalPrice: 4.99,
          offerPrice: 4.99,
          validFrom: now.subtract(const Duration(days: 1)),
          validUntil: now.add(const Duration(days: 5)),
          source: 'retailerWebsite',
          sourceAdapter: 'kaufda',
          branchId: 'lidl-branch-1',
          proofRef: 'https://example.test/kaufda/equal-amount',
          capturedAt: now,
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(result.learned, isEmpty);
    expect(result.stored, isEmpty);
  });

  test('filters offers and invalid periods and deduplicates refreshes', () async {
    final store = memoryStore();
    final offerOnly = OfferImportRecord(
      sourceId: 'offer-only',
      productLabel: current.productLabel,
      storeName: current.storeName,
      offerPrice: current.offerPrice,
      validFrom: current.validFrom,
      validUntil: current.validUntil,
      source: current.source,
      sourceAdapter: current.sourceAdapter,
      branchId: current.branchId,
      proofRef: current.proofRef,
      capturedAt: current.capturedAt,
    );
    final expired = current.copyWith(
      sourceId: 'expired',
      validFrom: DateTime(2026, 10, 1),
      validUntil: DateTime(2026, 10, 11),
    );
    final future = current.copyWith(
      sourceId: 'future',
      validFrom: DateTime(2026, 10, 13),
    );

    final first = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current, offerOnly, expired, future],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );
    final second = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(first.learned, hasLength(1));
    expect(first.learned.single.sourceAdapter, 'kaufda');
    expect(first.stored, hasLength(1));
    expect(second.learned, hasLength(1));
    expect(second.stored, hasLength(1));
    expect(second.stored.single.id, first.stored.single.id);
    expect(second.stored.single.price, 7.99);
  });

  test('refreshes the observation timestamp on repeated evidence', () async {
    final store = memoryStore();
    final first = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );
    final later = now.add(const Duration(hours: 6));
    final refreshed = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current.copyWith(capturedAt: later)],
      catalogProducts: const [coffee],
      observedAt: later,
      now: later,
    );

    expect(refreshed.learned, hasLength(1));
    expect(refreshed.stored, hasLength(1));
    expect(refreshed.stored.single.id, first.stored.single.id);
    expect(refreshed.stored.single.observedAt, later);
  });

  test(
    'removes legacy automatic prospect offer observations atomically',
    () async {
      final store = memoryStore();
      final legacy = prospectPriceObservations(
        records: [current],
        catalogProducts: const [coffee],
        observedAt: now,
      );
      expect(legacy, hasLength(2));
      expect(
        legacy.where((entry) => entry.kind == PriceObservationKind.offer),
        hasLength(1),
      );
      await store.replaceAll(legacy);

      final result = await persistCurrentProspectRegularPrices(
        store: store,
        records: [current],
        catalogProducts: const [coffee],
        observedAt: now,
        now: now,
      );

      expect(
        result.stored.where(
          (entry) =>
              entry.id.startsWith('prospect|') &&
              entry.kind == PriceObservationKind.offer,
        ),
        isEmpty,
      );
      expect(
        result.stored.where((entry) => entry.kind == PriceObservationKind.regular),
        hasLength(1),
      );
    },
  );

  test('removes legacy prospect offers without a feed timestamp', () async {
    final store = memoryStore();
    final legacy = prospectPriceObservations(
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
    );
    await store.replaceAll(legacy);

    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      now: now,
    );

    expect(result.learned, isEmpty);
    expect(
      result.stored.where(
        (entry) =>
            entry.id.startsWith('prospect|') &&
            entry.kind == PriceObservationKind.offer,
      ),
      isEmpty,
    );
    expect(
      result.stored.where((entry) => entry.kind == PriceObservationKind.regular),
      hasLength(1),
    );
  });

  test('does not persist without a feed timestamp', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      now: now,
    );

    expect(result.learned, isEmpty);
    expect(result.stored, isEmpty);
  });
  test('persists only a formatted regular amount from the parsed feed', () async {
    final feed = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-15T04:15:00Z",
  "sources": [
    {"storeName": "Lidl", "status": "ok", "branchId": "lidl-branch-1"}
  ],
  "offers": [
    {
      "sourceId": "formatted-persistence",
      "productLabel": "Jacobs Kaffee Crema 500 g",
      "storeName": "Lidl",
      "offerPrice": 4.99,
      "originalPrice": "7,99 €",
      "validFrom": "2026-10-10",
      "validUntil": "2026-10-17",
      "source": "retailerWebsite",
      "proofRef": "https://example.test/lidl/formatted-persistence",
      "capturedAt": "2026-10-12T12:00:00Z"
    }
  ]
}
''');
    final result = await persistCurrentProspectRegularPrices(
      store: memoryStore(),
      records: feed.records,
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(result.learned, hasLength(1));
    expect(result.learned.single.kind, PriceObservationKind.regular);
    expect(result.learned.single.price, 7.99);
    expect(result.learned.single.discounted, isFalse);
  });
}


extension on OfferImportRecord {
  OfferImportRecord copyWith({
    String? sourceId,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? capturedAt,
    String? branchId,
  }) =>
      OfferImportRecord(
        sourceId: sourceId ?? this.sourceId,
        productLabel: productLabel,
        storeName: storeName,
        originalPrice: originalPrice,
        offerPrice: offerPrice,
        validUntil: validUntil ?? this.validUntil,
        validFrom: validFrom ?? this.validFrom,
        source: source,
        proofRef: proofRef,
        packageSize: packageSize,
        sourceAdapter: sourceAdapter,
        regionalOnly: regionalOnly,
        brochureId: brochureId,
        brochurePage: brochurePage,
        publisherId: publisherId,
        capturedAt: capturedAt ?? this.capturedAt,
        branchId: branchId ?? this.branchId,
        location: location,
        address: address,
      );

  test('does not persist a regular price without an exact branch', () async {
    final store = memoryStore();
    final noBranch = OfferImportRecord(
      sourceId: 'leaflet-without-branch',
      productLabel: coffee.name,
      storeName: 'Lidl',
      originalPrice: 7.99,
      offerPrice: 4.99,
      validFrom: DateTime(2026, 10, 10),
      validUntil: DateTime(2026, 10, 17),
      source: 'leaflet',
      proofRef: 'https://example.test/lidl/coffee-no-branch',
      capturedAt: now,
    );

    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [noBranch],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(result.learned, isEmpty);
    expect(await store.load(), isEmpty);
  });
}
