import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_price_learning.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';

void main() {
  const coffee = Product(
    id: 'coffee-500',
    name: 'Jacobs Kaffee Crema 500 g',
    unit: '500 g',
    group: 'kaffee',
  );
  final observedAt = DateTime(2026, 9, 30, 15);

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
    expect(
      evidence.every((item) => item.validUntil == DateTime(2026, 9, 30)),
      isTrue,
    );
    expect(
      marketPricesFromObservations(
        evidence,
        products: const [coffee],
        now: DateTime(2026, 9, 30, 19),
      ),
      isEmpty,
    );
    expect(
      marketPricesFromObservations(
        evidence,
        products: const [coffee],
        now: DateTime(2026, 10, 1),
      ),
      isEmpty,
    );
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

  test('missing proof and invalid prices are never learned', () {
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
      ],
      catalogProducts: const [coffee],
      observedAt: observedAt,
    );
    expect(evidence, isEmpty);
  });
}
