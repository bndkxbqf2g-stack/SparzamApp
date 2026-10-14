import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_price_learning.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';

void main() {
  test('does not date prospect prices when the feed timestamp is missing', () {
    final evidence = datedProspectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'missing-time',
          productLabel: 'Kaffee 500 g',
          storeName: 'Lidl',
          offerPrice: 4.99,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 3),
          proofRef: 'https://example.test/offer',
        ),
      ],
      catalogProducts: const [],
    );

    expect(evidence, isEmpty);
  });

  test(
    'does not learn fallback records from a source that was not refreshed',
    () {
      final evidence = datedProspectPriceObservations(
        records: [
          OfferImportRecord(
            sourceId: 'fresh',
            productLabel: 'Kaffee 500 g',
            storeName: 'Lidl',
            offerPrice: 4.99,
            validUntil: DateTime(2026, 10, 3),
            proofRef: 'https://example.test/lidl/offer',
          ),
          OfferImportRecord(
            sourceId: 'fallback',
            productLabel: 'Kaffee 500 g',
            storeName: 'Netto',
            offerPrice: 3.99,
            validUntil: DateTime(2026, 10, 3),
            proofRef: 'https://example.test/netto/offer',
          ),
        ],
        catalogProducts: const [],
        observedAt: DateTime(2026, 10, 1),
        refreshedStores: const ['Lidl'],
      );

      expect(evidence, hasLength(1));
      expect(evidence.single.storeName, 'Lidl');
    },
  );

  test('matches refreshed stores case-insensitively and around whitespace', () {
    final evidence = datedProspectRegularPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'trimmed-store',
          productLabel: 'Kaffee 500 g',
          storeName: ' Kaufland ',
          originalPrice: 6.99,
          offerPrice: 4.99,
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/kaufland/coffee',
        ),
      ],
      catalogProducts: const [],
      observedAt: DateTime(2026, 10, 12, 8),
      refreshedStores: const ['KAUFLAND'],
    );

    expect(evidence, hasLength(1));
    expect(evidence.single.storeName, ' Kaufland ');
    expect(evidence.single.kind, PriceObservationKind.regular);
  });

  test('does not learn an equal original amount as a crossed-out price', () {
    final allEvidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'equal-amount',
          productLabel: 'Kaffee 500 g',
          storeName: 'Lidl',
          originalPrice: 4.99,
          offerPrice: 4.99,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/lidl/equal-amount',
        ),
      ],
      catalogProducts: const [],
      observedAt: DateTime(2026, 10, 12, 8),
    );

    expect(allEvidence, hasLength(1));
    expect(allEvidence.single.kind, PriceObservationKind.offer);
    expect(
      datedProspectRegularPriceObservations(
        records: [
          OfferImportRecord(
            sourceId: 'equal-amount',
            productLabel: 'Kaffee 500 g',
            storeName: 'Lidl',
            originalPrice: 4.99,
            offerPrice: 4.99,
            validFrom: DateTime(2026, 10, 12),
            validUntil: DateTime(2026, 10, 17),
            proofRef: 'https://example.test/lidl/equal-amount',
          ),
        ],
        catalogProducts: const [],
        observedAt: DateTime(2026, 10, 12, 8),
      ),
      isEmpty,
    );
  });

  test('automatic learning keeps only an explicitly stated regular price', () {
    final evidence = datedProspectRegularPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'with-regular',
          productLabel: 'Kaffee 500 g',
          storeName: 'Lidl',
          originalPrice: 6.99,
          offerPrice: 4.99,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/lidl/coffee',
        ),
        OfferImportRecord(
          sourceId: 'offer-only',
          productLabel: 'Milch 1 l',
          storeName: 'Lidl',
          offerPrice: 0.99,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/lidl/milk',
        ),
      ],
      catalogProducts: const [],
      observedAt: DateTime(2026, 10, 12, 8),
    );

    expect(evidence, hasLength(1));
    expect(evidence.single.kind, PriceObservationKind.regular);
    expect(evidence.single.price, 6.99);
    expect(evidence.single.discounted, isFalse);
  });

  const coffee = Product(
    id: 'coffee-500',
    name: 'Jacobs Kaffee Crema 500 g',
    unit: '500 g',
    group: 'kaffee',
  );
  final observedAt = DateTime(2026, 9, 30, 15);

  test('matches a canonical product core with an explicit package suffix', () {
    const coreCoffee = Product(
      id: 'coffee-core-500',
      name: 'Jacobs Kaffee Crema',
      unit: '500 g',
      group: 'kaffee',
      ean: '04012345678905',
    );
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'core-package',
          productLabel: 'Jacobs Kaffee Crema 500g',
          storeName: 'Lidl',
          originalPrice: 6.99,
          offerPrice: 4.99,
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/lidl/core-package',
        ),
      ],
      catalogProducts: const [coreCoffee],
      observedAt: observedAt,
    );

    expect(evidence, hasLength(2));
    expect(evidence.every((entry) => entry.productId == coreCoffee.id), isTrue);
    expect(evidence.every((entry) => entry.identityConfidence == 1), isTrue);
    expect(evidence.every((entry) => entry.ean == coreCoffee.ean), isTrue);
    expect(evidence.every((entry) => entry.quantity == 500), isTrue);
    expect(evidence.every((entry) => entry.unit == 'g'), isTrue);
  });

  test('keeps an unmatched source EAN on uncertain evidence', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'ean-mismatch',
          productLabel: 'Jacobs Kaffee Crema 500 g',
          ean: '04012345678906',
          storeName: 'Lidl',
          originalPrice: 6.99,
          offerPrice: 4.99,
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/lidl/ean-mismatch',
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: observedAt,
    );

    expect(evidence, hasLength(2));
    expect(evidence.every((entry) => entry.identityConfidence == 0), isTrue);
    expect(evidence.every((entry) => entry.ean == '04012345678906'), isTrue);
    expect(evidence.every((entry) => entry.productId!.startsWith('prospect|')), isTrue);
  });

  test('automatic regular learning ignores expired and future periods', () {
    final records = [
      OfferImportRecord(
        sourceId: 'expired',
        productLabel: 'Butter 250 g',
        storeName: 'Lidl',
        originalPrice: 2.49,
        offerPrice: 1.99,
        validFrom: DateTime(2026, 10, 1),
        validUntil: DateTime(2026, 10, 5),
        proofRef: 'https://example.test/lidl/expired',
      ),
      OfferImportRecord(
        sourceId: 'current',
        productLabel: 'Butter 250 g',
        storeName: 'Lidl',
        originalPrice: 2.49,
        offerPrice: 1.99,
        validFrom: DateTime(2026, 10, 10),
        validUntil: DateTime(2026, 10, 17),
        proofRef: 'https://example.test/lidl/current',
      ),
      OfferImportRecord(
        sourceId: 'future',
        productLabel: 'Butter 250 g',
        storeName: 'Lidl',
        originalPrice: 2.79,
        offerPrice: 2.29,
        validFrom: DateTime(2026, 10, 18),
        validUntil: DateTime(2026, 10, 24),
        proofRef: 'https://example.test/lidl/future',
      ),
    ];

    final evidence = currentDatedProspectRegularPriceObservations(
      records: records,
      catalogProducts: const [],
      observedAt: DateTime(2026, 10, 12, 8),
      now: DateTime(2026, 10, 12, 8),
    );

    expect(evidence, hasLength(1));
    expect(evidence.single.price, 2.49);
    expect(evidence.single.validFrom, DateTime(2026, 10, 10));
    expect(evidence.single.validUntil, DateTime(2026, 10, 17));
    expect(evidence.single.kind, PriceObservationKind.regular);
  });

  test('current prospect learns offer and stated regular price separately', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'coffee-netto-1',
          productLabel: coffee.name,
          storeName: 'Netto',
          originalPrice: 8,
          offerPrice: 5,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 9, 30),
          source: 'retailerWebsite',
          sourceAdapter: 'KaufDA',
          branchId: 'netto_4371',
          proofRef: 'https://example.test/netto/coffee',
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: observedAt,
    );

    expect(evidence, hasLength(2));
    expect(evidence.map((item) => item.price), [5, 8]);
    expect(evidence.map((item) => item.kind), [
      PriceObservationKind.offer,
      PriceObservationKind.regular,
    ]);
    expect(evidence.every((item) => item.productId == coffee.id), isTrue);
    expect(evidence.every((item) => item.quantity == 500), isTrue);
    expect(evidence.every((item) => item.unit == 'g'), isTrue);
    expect(evidence.every((item) => item.identityConfidence == 1), isTrue);
    expect(evidence.every((item) => item.proofRef != null), isTrue);
    expect(evidence.every((item) => item.sourceAdapter == 'KaufDA'), isTrue);
    expect(
      evidence.every((item) => item.validUntil == DateTime(2026, 9, 30)),
      isTrue,
    );
    final currentPrices = marketPricesFromObservations(
      evidence,
      products: const [coffee],
      now: DateTime(2026, 9, 30, 19),
    );
    expect(currentPrices, hasLength(1));
    expect(currentPrices.single.price, 8);
    expect(currentPrices.single.source, MarketPriceSource.prospect);
    expect(currentPrices.single.kind, PriceObservationKind.regular);
    expect(
      marketPricesFromObservations(
        evidence,
        products: const [coffee],
        now: DateTime(2026, 10, 1),
      ),
      isEmpty,
    );
  });

  test('multipack labels use the complete package quantity', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'multipack',
          productLabel: 'Riegel je 3 x 50-g-Packg.',
          storeName: 'Lidl',
          offerPrice: 2.49,
          validUntil: DateTime(2026, 10, 3),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/lidl/multipack',
        ),
      ],
      catalogProducts: const [],
      observedAt: observedAt,
    );

    expect(evidence.single.quantity, 150);
    expect(evidence.single.unit, 'g');
    expect(evidence.single.unitPrice, closeTo(16.6, 0.0001));
  });

  test('milligram package labels keep quantity and base price', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'vitamin-mg',
          productLabel: 'Vitamin C 250 mg',
          storeName: 'Lidl',
          offerPrice: 1,
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/lidl/vitamin-mg',
        ),
      ],
      catalogProducts: const [],
      observedAt: observedAt,
    );

    expect(evidence, hasLength(1));
    expect(evidence.single.quantity, 250);
    expect(evidence.single.unit, 'mg');
    expect(evidence.single.unitPrice, closeTo(4000, 0.0001));
  });

  test('KaufDA package metadata supplies quantity when the label omits it', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'kaufda-coffee',
          productLabel: 'Kaffee',
          packageSize: '500 g',
          storeName: 'Lidl',
          offerPrice: 2.49,
          validUntil: DateTime(2026, 10, 17),
          source: 'retailerWebsite',
          proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Kaffee',
          capturedAt: observedAt,
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: observedAt,
    );

    expect(evidence, hasLength(1));
    expect(evidence.single.productId, coffee.id);
    expect(evidence.single.quantity, 500);
    expect(evidence.single.unit, 'g');
    expect(evidence.single.unitPrice, closeTo(4.98, 0.0001));
  });

  test('regional-only KaufDA evidence is not learned as a price', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'regional-only',
          productLabel: coffee.name,
          storeName: 'Lidl',
          offerPrice: 4.99,
          validUntil: DateTime(2026, 10, 17),
          source: 'retailerWebsite',
          sourceAdapter: 'kaufda',
          regionalOnly: false,
          proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Kaffee',
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: observedAt,
    );

    expect(evidence, isEmpty);
  });

  test('variant ranges do not invent a package size', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'variant-range',
          productLabel: 'Milka Tafelschokolade je 100/95/90 g',
          storeName: 'Lidl',
          offerPrice: 1.11,
          validUntil: DateTime(2026, 10, 3),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/lidl/range',
        ),
      ],
      catalogProducts: const [],
      observedAt: observedAt,
    );

    expect(evidence.single.quantity, isNull);
    expect(evidence.single.unit, isNull);
    expect(evidence.single.unitPrice, isNull);
  });

  test('record capture time wins over the combined feed timestamp', () {
    final capturedAt = DateTime(2026, 10, 12, 8);
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'cached-kaufda',
          productLabel: coffee.name,
          storeName: 'Lidl',
          offerPrice: 4.99,
          validUntil: DateTime(2026, 10, 17),
          source: 'retailerWebsite',
          proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Kaffee',
          capturedAt: capturedAt,
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: DateTime(2026, 10, 12, 12),
    );

    expect(evidence.single.observedAt, capturedAt);
  });

  test('expired prospect remains dated history but cannot price a route', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'old-coffee',
          productLabel: coffee.name,
          storeName: 'Netto',
          originalPrice: 8,
          offerPrice: 5,
          validFrom: DateTime(2026, 9, 21),
          validUntil: DateTime(2026, 9, 27),
          source: 'leaflet',
          proofRef: 'https://example.test/netto/old',
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: observedAt,
    );

    expect(evidence, hasLength(2));
    expect(
      evidence.every((item) => item.validUntil == DateTime(2026, 9, 27)),
      isTrue,
    );
    expect(marketPricesFromObservations(evidence, now: observedAt), isEmpty);
  });

  test('unmatched or differently sized labels stay historical only', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'unknown-cheese',
          productLabel: 'Eigenmarke Käseaufschnitt 250 g',
          storeName: 'Lidl',
          offerPrice: 1.99,
          validUntil: DateTime(2026, 10, 3),
          source: 'leaflet',
          proofRef: 'https://example.test/lidl/cheese',
        ),
        OfferImportRecord(
          sourceId: 'wrong-size',
          productLabel: 'Jacobs Kaffee Crema 250 g',
          storeName: 'Netto',
          offerPrice: 3.99,
          validUntil: DateTime(2026, 10, 3),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/netto/coffee-250',
        ),
        OfferImportRecord(
          sourceId: 'different-brand',
          productLabel: 'Melitta Kaffee 500 g',
          storeName: 'Netto',
          offerPrice: 5,
          validUntil: DateTime(2026, 10, 3),
          source: 'leaflet',
          proofRef: 'https://example.test/netto/melitta',
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: observedAt,
    );

    expect(evidence, hasLength(3));
    expect(evidence.every((item) => item.identityConfidence == 0), isTrue);
    expect(
      evidence.every((item) => item.productId!.startsWith('prospect|')),
      isTrue,
    );
    expect(marketPricesFromObservations(evidence, now: observedAt), isEmpty);
  });

  test('missing or untrusted proof and invalid prices are never learned', () {
    final evidence = prospectPriceObservations(
      records: [
        OfferImportRecord(
          sourceId: 'unproven',
          productLabel: coffee.name,
          storeName: 'Netto',
          offerPrice: 5,
          validUntil: DateTime(2026, 10, 3),
          source: 'retailerWebsite',
        ),
        OfferImportRecord(
          sourceId: 'invalid',
          productLabel: coffee.name,
          storeName: 'Netto',
          originalPrice: 4,
          offerPrice: 5,
          validUntil: DateTime(2026, 10, 3),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/netto/invalid',
        ),
        OfferImportRecord(
          sourceId: 'unsafe-proof',
          productLabel: coffee.name,
          storeName: 'Netto',
          offerPrice: 5,
          validUntil: DateTime(2026, 10, 3),
          source: 'retailerWebsite',
          proofRef: 'javascript:alert(1)',
        ),
      ],
      catalogProducts: const [coffee],
      observedAt: observedAt,
    );
    expect(evidence, isEmpty);
  });
}

