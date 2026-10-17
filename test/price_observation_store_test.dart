import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/services/price_observation_store.dart';
import 'package:sparzamapp/services/price_observation_adapters.dart';
import 'package:sparzamapp/models/receipt_observation.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/features/route/market_price_quality.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('distinct prices persist, repeated imports are idempotent', () async {
    final store = PriceObservationStore();
    final older = observationFromMarketPrice(
      MarketPrice(
        productId: 'generic',
        storeName: 'Lidl',
        price: 0.79,
        updatedAt: DateTime(2026, 9, 1),
      ),
    );
    final newer = observationFromMarketPrice(
      MarketPrice(
        productId: 'generic',
        storeName: 'Lidl',
        price: 0.89,
        updatedAt: DateTime(2026, 9, 24),
      ),
    );
    await Future.wait([
      store.append([older]),
      store.append([newer]),
    ]);
    await store.append([older, newer]);
    final saved = await PriceObservationStore().load();
    expect(saved, hasLength(2));
    expect(saved.map((item) => item.price), containsAll([0.79, 0.89]));
  });

  test('quota recovery compacts automatic evidence and keeps receipts', () async {
    final raw = <String>[];
    var writes = 0;
    final store = PriceObservationStore(
      readRaw: () async => raw.isEmpty ? null : List<String>.of(raw),
      writeRaw: (values) async {
        writes++;
        if (writes == 1) {
          throw StateError(
            'QuotaExceededError: The quota has been exceeded.',
          );
        }
        raw
          ..clear()
          ..addAll(values);
      },
    );

    final receipt = PriceObservation(
      id: 'receipt|kept',
      productId: 'milk-15',
      familyKey: 'milch',
      storeName: 'Lidl',
      price: 0.95,
      observedAt: DateTime(2026, 10, 13),
      source: PriceObservationSource.receipt,
    );
    final automatic = [
      for (var index = 0; index < 4; index++)
        PriceObservation(
          id: 'prospect|$index',
          productId: 'milk-15',
          familyKey: 'milch',
          storeName: 'Lidl',
          price: 0.89 + index / 100,
          observedAt: DateTime(2026, 10, 10 + index),
          source: PriceObservationSource.retailerWebsite,
        ),
    ];

    final saved = await store.append([receipt, ...automatic]);

    expect(writes, 2);
    expect(saved.where((entry) => entry.source == PriceObservationSource.receipt),
        hasLength(1));
    expect(
      saved.where(
        (entry) => entry.source == PriceObservationSource.retailerWebsite,
      ),
      hasLength(1),
    );
    expect((await store.load()), hasLength(2));
  });

  test('keeps independent automatic source adapters in separate quota buckets', () {
    final observations = [
      for (final adapter in ['kaufda', 'retailer'])
        PriceObservation(
          id: 'prospect|$adapter',
          productId: 'coffee-500',
          storeName: 'Lidl',
          price: 7.99,
          observedAt: DateTime(2026, 10, 12),
          source: PriceObservationSource.retailerWebsite,
          sourceAdapter: adapter,
          kind: PriceObservationKind.regular,
        ),
    ];

    final compacted = compactPriceObservationsForStorage(
      observations,
      maxAutomaticEntries: 10,
      maxEntriesPerKey: 1,
    );

    expect(compacted, hasLength(2));
    expect(compacted.map((entry) => entry.sourceAdapter),
        containsAll(<String>['kaufda', 'retailer']));
  });

  test('retains current automatic evidence ahead of newer history', () {
    final observations = [
      PriceObservation(
        id: 'prospect|current',
        productId: 'coffee-500',
        storeName: 'Lidl',
        price: 7.99,
        observedAt: DateTime(2026, 10, 10),
        source: PriceObservationSource.retailerWebsite,
        sourceAdapter: 'kaufda',
        kind: PriceObservationKind.regular,
        isCurrent: true,
      ),
      for (var index = 0; index < 3; index++)
        PriceObservation(
          id: 'prospect|history-$index',
          productId: 'coffee-500',
          storeName: 'Lidl',
          price: 8.49 + index / 100,
          observedAt: DateTime(2026, 10, 11 + index),
          source: PriceObservationSource.retailerWebsite,
          sourceAdapter: 'kaufda',
          kind: PriceObservationKind.regular,
          isCurrent: false,
        ),
    ];

    final compacted = compactPriceObservationsForStorage(
      observations,
      maxAutomaticEntries: 10,
      maxEntriesPerKey: 3,
    );

    expect(compacted, hasLength(3));
    expect(compacted.any((entry) => entry.id == 'prospect|current'), isTrue);
    expect(
      compacted.where((entry) => entry.isCurrent),
      hasLength(1),
    );
  });

  test('a parallel read waits for a pending price observation write', () async {
    final store = PriceObservationStore();
    final reader = PriceObservationStore();
    final observation = observationFromMarketPrice(
      MarketPrice(
        productId: 'parallel',
        storeName: 'Lidl',
        price: 1.29,
        updatedAt: DateTime(2026, 9, 24),
      ),
    );

    final writing = store.append([observation]);
    final reading = reader.load();

    await writing;
    expect((await reading).single.price, 1.29);
  });

  test('stable derived evidence can be reinterpreted in place', () async {
    final store = PriceObservationStore();
    final old = PriceObservation(
      id: 'receipt|1',
      productId: 'tomato',
      familyKey: 'tomaten',
      storeName: 'Kaufland',
      price: 1.29,
      observedAt: DateTime(2026, 9, 20),
      source: PriceObservationSource.receipt,
      identityConfidence: 1,
    );
    final revised = PriceObservation(
      id: 'receipt|1',
      productId: 'tomato',
      familyKey: 'tomatenkonserve',
      storeName: 'Kaufland',
      price: 1.29,
      observedAt: DateTime(2026, 9, 20),
      source: PriceObservationSource.receipt,
      identityConfidence: 1,
    );

    await store.append([old]);
    await store.upsertById([revised]);
    final saved = await store.load();

    expect(saved, hasLength(1));
    expect(saved.single.familyKey, 'tomatenkonserve');
  });

  test('keeps newer automatic evidence when a stale cache arrives', () async {
    final store = PriceObservationStore();
    final newer = PriceObservation(
      id: 'prospect|same-id',
      productId: 'coffee-500',
      storeName: 'Lidl',
      price: 7.99,
      observedAt: DateTime(2026, 10, 15, 12),
      source: PriceObservationSource.retailerWebsite,
      sourceAdapter: 'kaufda',
      kind: PriceObservationKind.regular,
      identityConfidence: 1,
    );
    final stale = PriceObservation(
      id: 'prospect|same-id',
      productId: 'coffee-500',
      storeName: 'Lidl',
      price: 8.49,
      observedAt: DateTime(2026, 10, 15, 8),
      source: PriceObservationSource.retailerWebsite,
      sourceAdapter: 'kaufda',
      kind: PriceObservationKind.regular,
      identityConfidence: 1,
    );

    await store.append([newer]);
    final saved = await store.upsertById([stale]);

    expect(saved, hasLength(1));
    expect(saved.single.price, 7.99);
    expect(saved.single.observedAt, newer.observedAt);
  });

  test('automatic regular upsert rejects prospect offer amounts', () async {
    final store = PriceObservationStore();
    final regular = PriceObservation(
      id: 'prospect|regular-only',
      productId: 'milk-15',
      storeName: 'Lidl',
      price: 1.99,
      observedAt: DateTime(2026, 10, 17),
      source: PriceObservationSource.retailerWebsite,
      sourceAdapter: 'kaufda',
      kind: PriceObservationKind.regular,
    );
    final offer = PriceObservation(
      id: 'prospect|offer-only',
      productId: 'milk-15',
      storeName: 'Lidl',
      price: 1.49,
      observedAt: DateTime(2026, 10, 17),
      source: PriceObservationSource.retailerWebsite,
      sourceAdapter: 'kaufda',
      kind: PriceObservationKind.offer,
      discounted: true,
    );
    final discountedRegular = PriceObservation(
      id: 'prospect|discounted-regular',
      productId: 'milk-15',
      storeName: 'Lidl',
      price: 1.89,
      observedAt: DateTime(2026, 10, 17),
      source: PriceObservationSource.retailerWebsite,
      sourceAdapter: 'kaufda',
      kind: PriceObservationKind.regular,
      discounted: true,
    );

    final saved = await store.upsertAutomaticRegularById(
      [regular, offer, discountedRegular],
    );

    expect(saved.map((entry) => entry.id), ['prospect|regular-only']);
    expect(saved.single.kind, PriceObservationKind.regular);
    expect(saved.single.discounted, isFalse);
  });

  test('market price evidence survives central observation projection', () {
    final price = MarketPrice(
      productId: 'milk-15',
      storeName: 'Kaufland',
      price: 1.09,
      updatedAt: DateTime(2026, 9, 24),
      source: MarketPriceSource.receipt,
      discounted: true,
      proofRef: 'receipt:abc123|line:4',
      sourceAdapter: 'receipt-fixture',
      quantity: 1,
      unit: 'l',
      unitPrice: 1.09,
      kind: PriceObservationKind.offer,
      evidenceConfidence: EvidenceConfidence.manuallyConfirmed,
    );

    final restored = MarketPrice.fromJson(price.toJson());
    expect(restored.proofRef, price.proofRef);
    expect(restored.sourceAdapter, 'receipt-fixture');
    expect(restored.sourceLabel, 'Kassenbon');
    expect(restored.quantity, 1);
    expect(restored.unit, 'l');
    expect(restored.unitPrice, 1.09);
    expect(restored.kind, PriceObservationKind.offer);
    expect(restored.evidenceConfidence, EvidenceConfidence.manuallyConfirmed);

    final observation = observationFromMarketPrice(price);
    expect(observation.proofRef, price.proofRef);
    expect(observation.sourceAdapter, price.sourceAdapter);
    expect(observation.quantity, 1);
    expect(observation.unit, 'l');
    expect(observation.unitPrice, 1.09);
    expect(observation.kind, PriceObservationKind.offer);
    expect(observation.evidenceConfidence, EvidenceConfidence.manuallyConfirmed);

    final projected = marketPricesFromObservations(
      [observation],
      now: DateTime(2026, 9, 24),
    );
    expect(projected.single.proofRef, price.proofRef);
    expect(projected.single.sourceAdapter, price.sourceAdapter);
    expect(projected.single.quantity, 1);
    expect(projected.single.unit, 'l');
    expect(projected.single.unitPrice, 1.09);
    expect(projected.single.kind, PriceObservationKind.offer);
    expect(projected.single.evidenceConfidence, EvidenceConfidence.manuallyConfirmed);
  });

  test('record keeps branch, amount, offer validity and proof separately', () {
    final original = PriceObservation(
      id: 'shelf-1',
      productId: 'milk-15',
      familyKey: 'milch',
      variant: '1,5 %',
      ean: '4000000000001',
      storeName: 'Lidl',
      locationId: 'store-7',
      region: 'Zellingen',
      price: 1.09,
      quantity: 1,
      unit: 'l',
      unitPrice: 1.09,
      kind: PriceObservationKind.offer,
      validFrom: DateTime(2026, 9, 21),
      validUntil: DateTime(2026, 9, 27),
      observedAt: DateTime(2026, 9, 24),
      source: PriceObservationSource.shelfImage,
      sourceAdapter: 'fixture-adapter',
      identityConfidence: 0.9,
      proofRef: 'local-photo-7',
    );
    final restored = PriceObservation.fromJson(original.toJson());
    expect(restored.ean, original.ean);
    expect(restored.locationId, 'store-7');
    expect(restored.validUntil, DateTime(2026, 9, 27));
    expect(restored.proofRef, 'local-photo-7');
    expect(restored.identityConfidence, 0.9);
    expect(restored.sourceAdapter, 'fixture-adapter');
  });

  test('keeps the regular price field marker through JSON roundtrip', () {
    final original = PriceObservation(
      id: 'regular-marker',
      productId: 'coffee-500',
      storeName: 'Lidl',
      price: 7.99,
      observedAt: DateTime(2026, 10, 15),
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.regular,
      regularPriceSource: 'oldPrice',
      locationId: 'lidl-zellingen',
      validUntil: DateTime(2026, 10, 19),
      proofRef: 'https://example.test/regular-marker',
    );
    final restored = PriceObservation.fromJson(original.toJson());

    expect(restored.regularPriceSource, 'oldPrice');
  });

  test(
    'exact observation history projects every supported price for routing',
    () {
      final projected = marketPricesFromObservations([
        PriceObservation(
          id: 'old',
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.79,
          observedAt: DateTime(2026, 8, 1),
          source: PriceObservationSource.manual,
        ),
        PriceObservation(
          id: 'new',
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.89,
          observedAt: DateTime(2026, 9, 24),
          source: PriceObservationSource.openPrices,
          proofRef: 'open-prices:42',
        ),
      ]);

      expect(projected, hasLength(2));
      expect(projected.map((item) => item.price), containsAll([0.79, 0.89]));
      expect(projected.last.externalId, 42);
    },
  );

  test(
    'family-only or uncertain identity is not projected as exact route price',
    () {
      final projected = marketPricesFromObservations([
        PriceObservation(
          id: 'family',
          familyKey: 'schmand',
          storeName: 'Lidl',
          price: 0.69,
          observedAt: DateTime(2026, 9, 24),
          source: PriceObservationSource.manual,
        ),
        PriceObservation(
          id: 'uncertain',
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.59,
          observedAt: DateTime(2026, 9, 24),
          source: PriceObservationSource.manual,
          identityConfidence: 0.8,
        ),
      ]);

      expect(projected, isEmpty);
    },
  );

  test(
    'receipt adapter preserves quantity and family without faking identity',
    () {
      final observation = observationFromReceipt(
        ReceiptObservation(
          id: 'r1',
          receiptFingerprint: 'fp',
          rowLine: 1,
          rawLabel: 'SCHMAND 200G',
          familyKey: 'schmand',
          storeName: 'Lidl',
          observedAt: DateTime(2026, 9, 24),
          totalPrice: 0.69,
          quantity: 200,
          quantityUnit: 'g',
          unitPrice: 3.45,
          discounted: false,
        ),
      );
      expect(observation.familyKey, 'schmand');
      expect(observation.quantity, 200);
      expect(observation.identityConfidence, 0);
      expect(observation.kind, PriceObservationKind.regular);
    },
  );

  test(
    'receipt product id alone does not create exact identity confidence',
    () {
      final automatic = observationFromReceipt(
        ReceiptObservation(
          id: 'r-auto',
          receiptFingerprint: 'fp-auto',
          rowLine: 1,
          rawLabel: 'Unbekannte Spezialität',
          familyKey: 'unbekannte spezialitaet',
          storeName: 'Lidl',
          observedAt: DateTime(2026, 9, 24),
          totalPrice: 2.49,
          quantity: null,
          quantityUnit: 'Stück',
          unitPrice: null,
          discounted: false,
          productId: 'receipt_auto_specialitaet',
        ),
      );
      final confirmed = observationFromReceipt(
        ReceiptObservation(
          id: 'r-confirmed',
          receiptFingerprint: 'fp-confirmed',
          rowLine: 1,
          rawLabel: 'Schmand',
          familyKey: 'schmand',
          storeName: 'Lidl',
          observedAt: DateTime(2026, 9, 24),
          totalPrice: 0.69,
          quantity: null,
          quantityUnit: 'Stück',
          unitPrice: null,
          discounted: false,
          productId: 'schmand',
          identityConfirmed: true,
        ),
      );

      expect(automatic.productId, 'receipt_auto_specialitaet');
      expect(automatic.identityConfidence, 0);
      expect(confirmed.identityConfidence, 1);
    },
  );

  test('legacy automatic receipt ids migrate as unconfirmed', () {
    final restored = ReceiptObservation.fromJson({
      'id': 'legacy',
      'receiptFingerprint': 'legacy-fp',
      'rowLine': 1,
      'rawLabel': 'Unbekannte Spezialität',
      'familyKey': 'unbekannte spezialitaet',
      'storeName': 'Lidl',
      'observedAt': '2026-09-24T00:00:00.000',
      'totalPrice': 2.49,
      'quantity': null,
      'quantityUnit': 'Stück',
      'unitPrice': null,
      'discounted': false,
      'productId': 'receipt_auto_specialitaet',
    });

    expect(restored.identityConfirmed, isFalse);
    expect(observationFromReceipt(restored).identityConfidence, 0);
  });

  test('legacy receipt price observations default to unconfirmed identity', () {
    final restored = PriceObservation.fromJson({
      'id': 'receipt|legacy',
      'productId': 'schmand',
      'familyKey': 'schmand',
      'storeName': 'Lidl',
      'price': 0.69,
      'observedAt': '2026-09-24T00:00:00.000',
      'source': 'receipt',
    });

    expect(restored.identityConfidence, 0);
    expect(marketPricesFromObservations([restored]), isEmpty);
  });

  test('legacy non-receipt price observations keep exact identity', () {
    final restored = PriceObservation.fromJson({
      'id': 'manual|legacy',
      'productId': 'schmand',
      'storeName': 'Lidl',
      'price': 0.79,
      'observedAt': '2026-09-24T00:00:00.000',
      'source': 'manual',
    });

    expect(restored.identityConfidence, 1);
    expect(marketPricesFromObservations([restored]), hasLength(1));
  });

  test('offer adapter carries validity into observation', () {
    final observation = observationFromOffer(
      Offer(
        id: 'o1',
        productId: 'schmand',
        storeName: 'Lidl',
        originalPrice: 0.89,
        offerPrice: 0.69,
        validUntil: DateTime(2026, 9, 27),
      ),
      observedAt: DateTime(2026, 9, 24),
    );
    expect(observation.kind, PriceObservationKind.offer);
    expect(observation.validUntil, DateTime(2026, 9, 27));
    expect(observation.discounted, isTrue);
  });

  test('offer adapter derives a missing normalized package price', () {
    final observation = observationFromOffer(
      Offer(
        id: 'o-package',
        productId: 'coffee',
        storeName: 'Lidl',
        originalPrice: 4.99,
        offerPrice: 2.49,
        validUntil: DateTime(2026, 9, 27),
        packageAmount: 500,
        packageUnit: 'g',
      ),
      observedAt: DateTime(2026, 9, 24),
    );

    expect(observation.quantity, 500);
    expect(observation.unit, 'g');
    expect(observation.unitPrice, closeTo(4.98, 0.00001));
  });

  test('offer adapter keeps the source capture time as observation time', () {
    final capturedAt = DateTime(2026, 10, 12, 8, 15);
    final offer = Offer(
      id: 'kaufda-o1',
      productId: 'schmand',
      storeName: 'Lidl',
      originalPrice: 0.89,
      offerPrice: 0.69,
      validUntil: DateTime(2026, 10, 17),
      source: 'retailerWebsite',
      sourceAdapter: 'KaufDA',
      capturedAt: capturedAt,
      proofRef: 'https://www.kaufda.de/prospekt/example',
      locationId: 'lidl_zellingen',
      packageAmount: 200,
      packageUnit: 'g',
      unitPrice: 3.45,
    );
    final observation = observationFromOffer(
      offer,
      observedAt: observedAtForOffer(
        offer,
        fallback: DateTime(2026, 10, 13),
      ),
    );

    expect(observation.observedAt, capturedAt);
    expect(observation.proofRef, contains('kaufda'));
    expect(observation.sourceAdapter, 'KaufDA');
    expect(observation.identityConfidence, 1);
    expect(observation.quantity, 200);
    expect(observation.unit, 'g');
    expect(observation.unitPrice, closeTo(3.45, 0.00001));
  });

  test('legacy regional KaufDA offer is not an exact observation', () {
    final observation = observationFromOffer(
      Offer(
        id: 'regional-kaufda-o1',
        productId: 'schmand',
        storeName: 'Lidl',
        originalPrice: 0.89,
        offerPrice: 0.69,
        validUntil: DateTime(2026, 10, 17),
        source: 'retailerWebsite',
        sourceAdapter: 'KaufDA',
        proofRef: 'https://www.kaufda.de/prospekt/example',
      ),
      observedAt: DateTime(2026, 10, 13),
    );

    expect(observation.identityConfidence, 0);
  });

  test('external offer observations without proof cannot become exact route prices', () {
    final offer = Offer(
      id: 'leaflet-unproven',
      productId: 'schmand',
      storeName: 'Lidl',
      originalPrice: 0.89,
      offerPrice: 0.69,
      validUntil: DateTime(2026, 9, 27),
      source: 'leaflet',
    );
    final regular = regularObservationFromOffer(
      offer,
      observedAt: DateTime(2026, 9, 25),
    );
    final discounted = observationFromOffer(
      offer,
      observedAt: DateTime(2026, 9, 25),
    );

    expect(regular.identityConfidence, 0);
    expect(discounted.identityConfidence, 0);
    expect(
      marketPricesFromObservations([
        regular,
        discounted,
      ], now: DateTime(2026, 9, 25)),
      isEmpty,
    );
  });

  test('manual offer evidence stays confirmed without an external proof', () {
    final offer = Offer(
      id: 'manual-case-variant',
      productId: 'schmand',
      storeName: 'Lidl',
      originalPrice: 0.89,
      offerPrice: 0.69,
      validUntil: DateTime(2026, 9, 27),
      source: 'MANUAL',
    );

    expect(
      observationFromOffer(
        offer,
        observedAt: DateTime(2026, 9, 25),
      ).identityConfidence,
      1,
    );
  });

  test('external offer observations with unsafe proof stay uncertain', () {
    final offer = Offer(
      id: 'leaflet-unsafe-proof',
      productId: 'schmand',
      storeName: 'Lidl',
      originalPrice: 0.89,
      offerPrice: 0.69,
      validUntil: DateTime(2026, 9, 27),
      source: 'leaflet',
      proofRef: 'javascript:alert(1)',
    );
    final observations = observationsFromOffer(
      offer,
      observedAt: DateTime(2026, 9, 25),
    ).toList(growable: false);

    expect(observations, hasLength(2));
    expect(observations.every((entry) => entry.identityConfidence == 0), isTrue);
    expect(
      marketPricesFromObservations(observations, now: DateTime(2026, 9, 25)),
      isEmpty,
    );
  });

  test('leaflet preserves regular price as separate evidence', () {
    final offer = Offer(
      id: 'leaflet-1',
      productId: 'chocolate',
      storeName: 'Lidl',
      originalPrice: 2.19,
      offerPrice: 1.99,
      validFrom: DateTime(2026, 9, 25),
      validUntil: DateTime(2026, 9, 26),
      source: 'leaflet',
      proofRef: 'leaflet:lidl:2026-09-25:p1',
      locationId: 'L-42',
      region: 'Zellingen',
      packageAmount: 100,
      packageUnit: 'g',
      unitPrice: 19.9,
    );
    final regular = regularObservationFromOffer(
      offer,
      observedAt: DateTime(2026, 9, 25),
    );
    final discounted = observationFromOffer(
      offer,
      observedAt: DateTime(2026, 9, 25),
    );

    expect(regular.price, 2.19);
    expect(regular.kind, PriceObservationKind.regular);
    expect(regular.source, PriceObservationSource.leaflet);
    expect(regular.proofRef, offer.proofRef);
    expect(regular.locationId, 'L-42');
    expect(regular.region, 'Zellingen');
    expect(regular.validUntil, DateTime(2026, 9, 26));
    expect(regular.quantity, 100);
    expect(regular.unit, 'g');
    expect(regular.unitPrice, closeTo(21.9, 0.00001));
    expect(discounted.price, 1.99);
    expect(discounted.kind, PriceObservationKind.offer);
    expect(discounted.validFrom, DateTime(2026, 9, 25));
    expect(discounted.locationId, 'L-42');
    expect(discounted.region, 'Zellingen');
    expect(discounted.source, PriceObservationSource.leaflet);
    expect(discounted.quantity, 100);
    expect(discounted.unit, 'g');
    expect(discounted.unitPrice, closeTo(19.9, 0.00001));
  });

  test('exact route projection rejects a different declared package size', () {
    const product = Product(
      id: 'schmand-200',
      name: 'Schmand 200 g',
      unit: '200 g',
      group: 'schmand',
      packageAmount: 200,
      packageUnit: 'g',
    );
    final projected = marketPricesFromObservations(
      [
        PriceObservation(
          id: 'wrong-pack',
          productId: product.id,
          storeName: 'Lidl',
          price: 0.69,
          quantity: 500,
          unit: 'g',
          observedAt: DateTime(2026, 9, 24),
          source: PriceObservationSource.receipt,
        ),
        PriceObservation(
          id: 'right-pack',
          productId: product.id,
          storeName: 'Edeka',
          price: 0.89,
          quantity: 0.2,
          unit: 'kg',
          observedAt: DateTime(2026, 9, 24),
          source: PriceObservationSource.receipt,
        ),
      ],
      products: const [product],
    );

    expect(projected, hasLength(1));
    expect(projected.single.storeName, 'Edeka');
  });

  test('disabled Open Prices history cannot re-enter route planning', () {
    final projected = marketPricesFromObservations(
      [
        PriceObservation(
          id: 'open',
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.69,
          observedAt: DateTime(2026, 9, 24),
          source: PriceObservationSource.openPrices,
        ),
        PriceObservation(
          id: 'manual',
          productId: 'schmand',
          storeName: 'Edeka',
          price: 0.89,
          observedAt: DateTime(2026, 9, 24),
          source: PriceObservationSource.manual,
        ),
      ],
      settings: const PriceDataSettings(openPricesEnabled: false),
      now: DateTime(2026, 9, 24),
    );

    expect(projected, hasLength(1));
    expect(projected.single.storeName, 'Edeka');
  });

  test('verified leaflet regular price remains historical evidence', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'leaflet-regular',
        productId: 'chocolate',
        storeName: 'Lidl',
        locationId: 'lidl-branch-1',
        price: 2.19,
        observedAt: DateTime(2026, 9, 25),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.regular,
        validFrom: DateTime(2026, 9, 25),
        validUntil: DateTime(2026, 9, 26),
        proofRef: 'leaflet:lidl:2026-09-25:p1',
      ),
    ], now: DateTime(2026, 9, 25));

    expect(projected, hasLength(1));
    expect(projected.single.source, MarketPriceSource.prospect);
    expect(projected.single.price, 2.19);
    expect(projected.single.kind, PriceObservationKind.regular);
  });

  test('legacy leaflet reference without validity stays history only', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'old-leaflet-regular',
        productId: 'chocolate',
        storeName: 'Lidl',
        price: 2.19,
        observedAt: DateTime(2026, 9, 25),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.regular,
        proofRef: 'leaflet:lidl:2026-09-25:p1',
      ),
    ], now: DateTime(2026, 9, 25));

    expect(projected, isEmpty);
  });

  test('future offer validity cannot enter route planning early', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'future-offer',
        productId: 'schmand',
        storeName: 'Lidl',
        price: 0.49,
        observedAt: DateTime(2026, 9, 24),
        validFrom: DateTime(2026, 10, 1),
        validUntil: DateTime(2026, 10, 7),
        source: PriceObservationSource.manual,
        kind: PriceObservationKind.offer,
      ),
    ], now: DateTime(2026, 9, 25));

    expect(projected, isEmpty);
  });

  test('future observation timestamps stay out of market price projection', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'future-observation',
        productId: 'schmand',
        storeName: 'Lidl',
        price: 0.99,
        observedAt: DateTime(2026, 10, 1),
        validFrom: DateTime(2026, 9, 25),
        validUntil: DateTime(2026, 10, 7),
        source: PriceObservationSource.manual,
      ),
    ], now: DateTime(2026, 9, 25));

    expect(projected, isEmpty);
  });

  test('invalid observation cannot bypass store validation into routing', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'invalid',
        productId: 'schmand',
        storeName: 'Lidl',
        price: -0.49,
        observedAt: DateTime(2026, 9, 24),
        source: PriceObservationSource.manual,
      ),
    ], now: DateTime(2026, 9, 25));

    expect(projected, isEmpty);
  });

  test('old Open Prices history respects configured maximum age', () {
    final projected = marketPricesFromObservations(
      [
        PriceObservation(
          id: 'old-open',
          productId: 'schmand',
          storeName: 'Lidl',
          price: 0.69,
          observedAt: DateTime(2026, 7, 1),
          source: PriceObservationSource.openPrices,
        ),
      ],
      settings: const PriceDataSettings(openPricesMaxAgeDays: 30),
      now: DateTime(2026, 9, 24),
    );

    expect(projected, isEmpty);
  });

  test('old exact receipt history is excluded from route price projection', () {
    final projected = marketPricesFromObservations([
      PriceObservation(
        id: 'old-receipt',
        productId: 'schmand',
        storeName: 'Lidl',
        price: 0.69,
        observedAt: DateTime(2026, 8, 24),
        source: PriceObservationSource.receipt,
      ),
    ], now: DateTime(2026, 9, 25));

    expect(projected, isEmpty);
  });

  test('receipt age uses the same calendar-day cutoff as market prices', () {
    final onCutoff = marketPricesFromObservations([
      PriceObservation(
        id: 'receipt-on-cutoff-day',
        productId: 'schmand',
        storeName: 'Lidl',
        price: 0.69,
        observedAt: DateTime(2026, 8, 26, 0, 1),
        source: PriceObservationSource.receipt,
      ),
    ], now: DateTime(2026, 9, 25, 23, 0));
    final beforeCutoff = marketPricesFromObservations([
      PriceObservation(
        id: 'receipt-before-cutoff-day',
        productId: 'schmand',
        storeName: 'Lidl',
        price: 0.69,
        observedAt: DateTime(2026, 8, 25, 23, 59),
        source: PriceObservationSource.receipt,
      ),
    ], now: DateTime(2026, 9, 25, 23, 0));

    expect(onCutoff, hasLength(1));
    expect(beforeCutoff, isEmpty);
  });

  test('source confidence and age confidence are separate', () {
    final old = MarketPrice(
      productId: 'x',
      storeName: 'Lidl',
      price: 0.79,
      updatedAt: DateTime(2026, 7, 23),
      source: MarketPriceSource.receipt,
      discounted: true,
    );
    final quality = marketPriceQuality(old, DateTime(2026, 9, 24));
    expect(quality.sourceRate, 0.05);
    expect(quality.ageRate, 0.20);
    expect(quality.discountRate, 0.10);
    expect(quality.confidence, closeTo(0.65, 0.00001));
  });
  test('offer adapter normalizes known prospect source token variants', () {
    Offer offer(String source) => Offer(
          id: 'source-$source',
          productId: 'schmand',
          storeName: 'Lidl',
          originalPrice: 0.89,
          offerPrice: 0.69,
          validUntil: DateTime(2026, 10, 17),
          source: source,
          proofRef: 'https://example.test/lidl/$source',
        );

    for (final source in const [
      ' RETAILERWEBSITE ',
      'retailer_website',
      'retailer-website',
    ]) {
      final observation = observationFromOffer(
        offer(source),
        observedAt: DateTime(2026, 10, 15),
      );
      expect(observation.source, PriceObservationSource.retailerWebsite);
    }

    expect(
      observationFromOffer(
        offer('retailer website'),
        observedAt: DateTime(2026, 10, 15),
      ).source,
      PriceObservationSource.manual,
    );
  });

}

