import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_regular_price_persistence.dart';
import 'package:sparzamapp/features/offers/prospect_offer_products.dart';
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
    regularPriceSource: 'originalPrice',
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

  test('persists a regular price from a record capture time without feed time', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      now: now,
    );

    expect(result.learned, hasLength(1));
    expect(result.learned.single.kind, PriceObservationKind.regular);
    expect(result.learned.single.observedAt, now);
    expect(result.stored.single.price, 7.99);
  });

  test(
    'uses the exact generated prospect product for an unknown regular price',
    () async {
      final record = OfferImportRecord(
        sourceId: 'unknown-regular-price',
        productLabel: 'Eigenmarke Haferdrink 1 l',
        storeName: 'Lidl',
        originalPrice: 1.49,
        regularPriceSource: 'originalPrice',
        offerPrice: 0.99,
        validFrom: now.subtract(const Duration(days: 1)),
        validUntil: now.add(const Duration(days: 2)),
        source: 'retailerWebsite',
        sourceAdapter: 'kaufda',
        branchId: 'lidl-branch-unknown',
        proofRef: 'https://example.test/lidl/unknown-regular-price',
        capturedAt: now,
      );
      final offerProducts = prospectOfferProducts(
        records: [record],
        catalogProducts: const <Product>[],
        now: now,
      );
      final catalog = catalogProductsWithProspectOffers(
        catalogProducts: const <Product>[],
        offerProducts: offerProducts,
      );

      final result = await persistCurrentProspectRegularPrices(
        store: memoryStore(),
        records: [record],
        catalogProducts: catalog,
        observedAt: now,
        now: now,
      );

      expect(offerProducts, hasLength(1));
      expect(catalog, hasLength(1));
      expect(result.learned, hasLength(1));
      expect(result.learned.single.productId, offerProducts.single.product.id);
      expect(result.learned.single.identityConfidence, 1);
    },
  );

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
          regularPriceSource: 'originalPrice',
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

  test('marks a changed active price historical while keeping the new one current', () async {
    final store = memoryStore();
    final first = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
      refreshedStores: const ['Lidl'],
    );
    expect(first.stored.single.isCurrent, isTrue);

    final changed = OfferImportRecord(
      sourceId: 'kaufda-coffee-price-change',
      productLabel: current.productLabel,
      storeName: current.storeName,
      originalPrice: 8.49,
      regularPriceSource: current.regularPriceSource,
      offerPrice: 5.49,
      validFrom: current.validFrom,
      validUntil: current.validUntil,
      source: current.source,
      sourceAdapter: current.sourceAdapter,
      branchId: current.branchId,
      proofRef: 'https://example.test/kaufda/coffee-price-change',
      capturedAt: now.add(const Duration(hours: 6)),
    );
    final refreshed = await persistCurrentProspectRegularPrices(
      store: store,
      records: [changed],
      catalogProducts: const [coffee],
      observedAt: changed.capturedAt,
      now: changed.capturedAt,
      refreshedStores: const ['Lidl'],
    );

    expect(refreshed.stored, hasLength(2));
    final currentRows =
        refreshed.stored.where((entry) => entry.isCurrent).toList();
    expect(currentRows, hasLength(1));
    expect(currentRows.single.price, 8.49);
    expect(
      refreshed.stored.singleWhere((entry) => entry.price == 7.99).isCurrent,
      isFalse,
    );
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

  test('reconciles an unchanged feed after local regular-price loss', () async {
    var raw = <String>[];
    final store = PriceObservationStore(
      readRaw: () async => raw,
      writeRaw: (values) async => raw = [...values],
    );

    final first = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );
    expect(first.stored, hasLength(1));

    // Simulate a local store reset while the feed fingerprint remains
    // unchanged in the running shell.
    raw = <String>[];

    final reconciled = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(reconciled.learned, hasLength(1));
    expect(reconciled.stored, hasLength(1));
    expect(reconciled.stored.single.kind, PriceObservationKind.regular);
    expect(reconciled.stored.single.price, 7.99);
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

  test('removes legacy prospect offers while using record capture time', () async {
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

    expect(result.learned, hasLength(1));
    expect(result.learned.single.kind, PriceObservationKind.regular);
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

  test('purges legacy discounted prospect rows even when kind is unknown', () async {
    final store = memoryStore();
    final legacy = PriceObservation(
      id: 'prospect|retailerWebsite|Lidl|legacy-discount',
      productId: coffee.id,
      storeName: 'Lidl',
      price: 4.99,
      observedAt: now,
      source: PriceObservationSource.retailerWebsite,
      kind: PriceObservationKind.unknown,
      discounted: true,
      locationId: 'lidl-branch-1',
      proofRef: 'https://example.test/lidl/legacy-discount',
    );
    final regular = PriceObservation(
      id: 'prospect|retailerWebsite|Lidl|legacy-regular',
      productId: coffee.id,
      storeName: 'Lidl',
      price: 7.99,
      observedAt: now,
      source: PriceObservationSource.retailerWebsite,
      kind: PriceObservationKind.regular,
      locationId: 'lidl-branch-1',
      proofRef: 'https://example.test/lidl/legacy-regular',
    );
    await store.replaceAll([legacy, regular]);

    final purged = await purgeLegacyAutomaticProspectOfferObservations(
      store: store,
    );

    expect(purged.any((entry) => entry.id == legacy.id), isFalse);
    expect(purged.any((entry) => entry.id == regular.id), isTrue);
  });

  test('persists from record capture time without a feed timestamp', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      now: now,
    );

    expect(result.learned, hasLength(1));
    expect(result.learned.single.observedAt, now);
    expect(result.stored, hasLength(1));
    expect(result.stored.single.kind, PriceObservationKind.regular);
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
  test('removes legacy imported offer observations but keeps regular evidence', () async {
    final store = memoryStore();
    final legacyOffer = PriceObservation(
      id: 'offer|import|legacy',
      productId: coffee.id,
      storeName: 'Lidl',
      price: 4.99,
      observedAt: now,
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.offer,
      locationId: 'lidl-branch-1',
      proofRef: 'https://example.test/lidl/legacy-offer',
    );
    await store.replaceAll([legacyOffer]);

    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );

    expect(result.stored.any((entry) => entry.id == legacyOffer.id), isFalse);
    expect(
      result.stored.where((entry) => entry.kind == PriceObservationKind.regular),
      hasLength(1),
    );
  });
  test('purges legacy automatic offer observations without a feed refresh', () async {
    final store = memoryStore();
    final legacy = prospectPriceObservations(
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
    );
    await store.replaceAll(legacy);

    final purged = await purgeLegacyAutomaticProspectOfferObservations(
      store: store,
    );

    expect(
      purged.where((entry) => entry.kind == PriceObservationKind.offer),
      isEmpty,
    );
    expect(
      purged.where((entry) => entry.kind == PriceObservationKind.regular),
      hasLength(1),
    );
  });

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

  test(
    'keeps a removed prospect price as history but excludes it after refresh',
    () async {
      final store = memoryStore();
      final first = await persistCurrentProspectRegularPrices(
        store: store,
        records: [current],
        catalogProducts: const [coffee],
        observedAt: now,
        now: now,
        refreshedStores: const ['Lidl'],
      );
      expect(first.stored, hasLength(1));
      expect(first.stored.single.isCurrent, isTrue);

      final refreshed = await persistCurrentProspectRegularPrices(
        store: store,
        records: const [],
        catalogProducts: const [coffee],
        observedAt: now.add(const Duration(hours: 1)),
        now: now.add(const Duration(hours: 1)),
        refreshedStores: const ['Lidl'],
      );

      expect(refreshed.learned, isEmpty);
      expect(refreshed.stored, hasLength(1));
      expect(refreshed.stored.single.isCurrent, isFalse);
      expect(
        marketPricesFromObservations(
          refreshed.stored,
          products: const [coffee],
          now: now.add(const Duration(hours: 1)),
        ),
        isEmpty,
      );
      expect((await store.load()).single.isCurrent, isFalse);
    },
  );

  test('reconciles umlaut retailer labels in the refresh scope', () async {
    final store = memoryStore();
    final aldi = OfferImportRecord(
      sourceId: 'aldi-coffee-current',
      productLabel: coffee.name,
      storeName: 'ALDI Süd',
      originalPrice: 7.49,
      regularPriceSource: 'originalPrice',
      offerPrice: 4.49,
      validFrom: DateTime(2026, 10, 10),
      validUntil: DateTime(2026, 10, 17),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      branchId: 'aldi-branch-1',
      proofRef: 'https://example.test/kaufda/aldi-coffee',
      capturedAt: now,
    );

    final first = await persistCurrentProspectRegularPrices(
      store: store,
      records: [aldi],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
      refreshedStores: const ['ALDI SUED'],
    );
    expect(first.stored.single.isCurrent, isTrue);

    final refreshed = await persistCurrentProspectRegularPrices(
      store: store,
      records: const [],
      catalogProducts: const [coffee],
      observedAt: now.add(const Duration(hours: 1)),
      now: now.add(const Duration(hours: 1)),
      refreshedStores: const ['ALDI SUED'],
    );

    expect(refreshed.stored.single.storeName, 'ALDI Süd');
    expect(refreshed.stored.single.isCurrent, isFalse);
  });
  test('does not reconcile stores outside the confirmed refresh scope', () async {
    final store = memoryStore();
    final netto = OfferImportRecord(
      sourceId: 'netto-coffee-current',
      productLabel: coffee.name,
      storeName: 'Netto',
      originalPrice: 8.49,
      regularPriceSource: 'originalPrice',
      offerPrice: 5.49,
      validFrom: DateTime(2026, 10, 10),
      validUntil: DateTime(2026, 10, 17),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      branchId: 'netto-branch-1',
      proofRef: 'https://example.test/kaufda/netto-coffee',
      capturedAt: now,
    );
    final first = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current, netto],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
      refreshedStores: const ['Lidl', 'Netto'],
    );
    expect(first.stored, hasLength(2));

    final refreshed = await persistCurrentProspectRegularPrices(
      store: store,
      records: const [],
      catalogProducts: const [coffee],
      observedAt: now.add(const Duration(hours: 1)),
      now: now.add(const Duration(hours: 1)),
      refreshedStores: const ['Lidl'],
    );

    final byStore = <String, PriceObservation>{
      for (final entry in refreshed.stored) entry.storeName: entry,
    };
    expect(byStore['Lidl']?.isCurrent, isFalse);
    expect(byStore['Netto']?.isCurrent, isTrue);
  });

  test('defaults legacy observations to current during JSON migration', () async {
    final store = memoryStore();
    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [current],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
    );
    final legacy = Map<String, dynamic>.from(result.stored.single.toJson())
      ..remove('isCurrent');

    expect(PriceObservation.fromJson(legacy).isCurrent, isTrue);
  });
  test('speichert einen manuell geprüften Seiten-Normalpreis separat', () async {
    final observation = reviewedProspectRegularPriceObservation(
      record: current.copyWith(sourceId: 'manual-page-test'),
      catalogProducts: const [coffee],
      now: now,
    );

    expect(observation, isNotNull);
    expect(observation!.id, startsWith('manual-page|manual-page-test|regular|'));
    expect(observation.kind, PriceObservationKind.regular);
    expect(observation.price, 7.99);
    expect(observation.evidenceConfidence, EvidenceConfidence.manuallyConfirmed);
    expect(observation.discounted, isFalse);
    expect(observation.locationId, 'lidl-branch-1');
    expect(observation.proofRef, current.proofRef);
    expect(isKnownProspectRegularPriceSource('manualPage'), isTrue);
  });

  test('verwirft Seiten-Normalpreise ohne Nachweis, Zeitstempel oder Filiale', () {
    final noProof = OfferImportRecord(
      sourceId: 'manual-page-no-proof',
      productLabel: coffee.name,
      storeName: 'Lidl',
      originalPrice: 7.99,
      regularPriceSource: 'manualPage',
      offerPrice: 4.99,
      validFrom: DateTime(2026, 10, 10),
      validUntil: DateTime(2026, 10, 17),
      source: 'leaflet',
      branchId: 'lidl-branch-1',
      capturedAt: now,
    );
    final noBranch = OfferImportRecord(
      sourceId: 'manual-page-no-branch',
      productLabel: coffee.name,
      storeName: 'Lidl',
      originalPrice: 7.99,
      regularPriceSource: 'manualPage',
      offerPrice: 4.99,
      validFrom: DateTime(2026, 10, 10),
      validUntil: DateTime(2026, 10, 17),
      source: 'leaflet',
      sourceAdapter: 'kaufda',
      proofRef: 'https://example.test/kaufda/manual-page-no-branch',
      capturedAt: now,
    );
    final noCapture = noProof.copyWith(sourceId: 'manual-page-no-capture');

    expect(
      reviewedProspectRegularPriceObservation(
        record: noProof,
        catalogProducts: const [coffee],
        now: now,
      ),
      isNull,
    );
    expect(
      reviewedProspectRegularPriceObservation(
        record: noBranch,
        catalogProducts: const [coffee],
        now: now,
      ),
      isNull,
    );
    expect(
      reviewedProspectRegularPriceObservation(
        record: noCapture.copyWith(capturedAt: null),
        catalogProducts: const [coffee],
        now: now,
      ),
      isNull,
    );
  });

  test('manueller Seiten-Normalpreis bleibt bei Feed-Reconciliation geschützt', () async {
    final store = memoryStore();
    final manual = reviewedProspectRegularPriceObservation(
      record: current.copyWith(sourceId: 'manual-page-persistent'),
      catalogProducts: const [coffee],
      now: now,
    );
    expect(manual, isNotNull);
    await store.upsertById([manual!]);

    final refreshed = await persistCurrentProspectRegularPrices(
      store: store,
      records: const [],
      catalogProducts: const [coffee],
      observedAt: now.add(const Duration(hours: 1)),
      now: now.add(const Duration(hours: 1)),
      refreshedStores: const ['Lidl'],
    );

    expect(refreshed.stored, hasLength(1));
    expect(refreshed.stored.single.evidenceConfidence,
        EvidenceConfidence.manuallyConfirmed);
    expect(refreshed.stored.single.isCurrent, isTrue);
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
        regularPriceSource: regularPriceSource,
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

}
