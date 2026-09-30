import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_offer_products.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  final current = DateTime(2026, 9, 30);

  test('verified unknown offer becomes searchable under its exact label', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'coffee-netto-1',
          productLabel: 'Jacobs Kaffee Crema 500 g',
          storeName: 'Netto',
          originalPrice: 8,
          offerPrice: 5,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/netto/coffee',
        ),
      ],
      catalogProducts: const <Product>[],
      now: current,
    );

    expect(entries, hasLength(1));
    expect(entries.single.product.id, 'prospect|jacobs kaffee crema 500 g');
    expect(entries.single.product.name, 'Jacobs Kaffee Crema 500 g');
    expect(entries.single.product.unit, '500 g');
    expect(entries.single.offer.productId, entries.single.product.id);
    expect(entries.single.offer.originalPriceVerified, isTrue);
    expect(entries.single.offer.proofRef, contains('netto/coffee'));
  });

  test('matching exact catalog identity is reused across stores', () {
    const coffee = Product(
      id: 'coffee-jacobs-500',
      name: 'Jacobs Kaffee Crema 500 g',
      unit: '500 g',
      group: 'kaffee',
    );
    final entries = prospectOfferProducts(
      records: [
        for (final store in ['Netto', 'Lidl'])
          OfferImportRecord(
            sourceId: '$store-coffee',
            productLabel: 'Jacobs Kaffee Crema 500 g',
            storeName: store,
            offerPrice: store == 'Netto' ? 5 : 6,
            validUntil: DateTime(2026, 10, 2),
            source: 'retailerWebsite',
            proofRef: 'https://example.test/$store/coffee',
          ),
      ],
      catalogProducts: const [coffee],
      now: current,
    );

    expect(entries.map((entry) => entry.product.id), everyElement(coffee.id));
    expect(
      entries.map((entry) => entry.offer.productId),
      everyElement(coffee.id),
    );
  });

  test('expired, unproven, and invalid price records are excluded', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'expired',
          productLabel: 'Kaffee 500 g',
          storeName: 'Lidl',
          offerPrice: 5,
          validUntil: DateTime(2026, 9, 29),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/expired',
        ),
        OfferImportRecord(
          sourceId: 'unproven',
          productLabel: 'Kaffee 500 g',
          storeName: 'Lidl',
          offerPrice: 5,
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
        ),
        OfferImportRecord(
          sourceId: 'invalid',
          productLabel: 'Kaffee 500 g',
          storeName: 'Lidl',
          originalPrice: 4,
          offerPrice: 5,
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/invalid',
        ),
      ],
      catalogProducts: const <Product>[],
      now: current,
    );

    expect(entries, isEmpty);
  });
}
