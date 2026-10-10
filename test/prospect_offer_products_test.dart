import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_offer_products.dart';
import 'package:sparzamapp/models/list_item.dart';
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

  test('preserves multipack quantity for price comparability', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'snack-multipack',
          productLabel: 'Riegel je 3 x 50-g-Packg.',
          storeName: 'Lidl',
          offerPrice: 2.49,
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/lidl/snack',
        ),
      ],
      catalogProducts: const <Product>[],
      now: current,
    );

    expect(entries, hasLength(1));
    expect(entries.single.product.unit, '3 x 50 g');
    expect(entries.single.product.packageAmount, 150);
    expect(entries.single.product.packageUnit, 'g');
  });

  test('preserves multipack volume from retailer labels', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'water-case',
          productLabel: 'Mineralwasser je 6 x 1,5-l-Fl.',
          storeName: 'Netto',
          offerPrice: 3.99,
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/netto/water',
        ),
      ],
      catalogProducts: const <Product>[],
      now: current,
    );

    expect(entries.single.product.unit, '6 x 1,5 l');
    expect(entries.single.product.packageAmount, 9);
    expect(entries.single.product.packageUnit, 'l');
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

  test('unknown verified prospect offer remains routeable by exact label', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'unknown-milk',
          productLabel: 'Landmilch 1 l',
          storeName: 'Lidl',
          offerPrice: 0.89,
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/lidl/milk',
        ),
      ],
      catalogProducts: const <Product>[],
      now: current,
    );
    final product = entries.single.product;
    final offers = offersFromProspectProducts(entries);

    final plan = RouteOptimizer(
      [ListItem(product: product)],
      offers,
      enabledStoreNames: const ['Lidl'],
      maxStores: 1,
      now: current,
    ).bestSingleStorePlan();

    expect(product.id, startsWith('prospect|'));
    expect(offers.single.productId, product.id);
    expect(plan, isNotNull);
    expect(plan!.unassigned, isEmpty);
    expect(plan.basket, 0.89);
  });

  test(
    'different brand in same family never inherits catalog price identity',
    () {
      const coffee = Product(
        id: 'coffee-jacobs-500',
        name: 'Jacobs Kaffee Crema 500 g',
        unit: '500 g',
        group: 'kaffee',
      );
      final entries = prospectOfferProducts(
        records: [
          OfferImportRecord(
            sourceId: 'melitta-500',
            productLabel: 'Melitta Kaffee 500 g',
            storeName: 'Netto',
            offerPrice: 5,
            validUntil: DateTime(2026, 10, 2),
            source: 'leaflet',
            proofRef: 'https://example.test/netto/melitta',
          ),
        ],
        catalogProducts: const [coffee],
        now: current,
      );

      expect(entries, hasLength(1));
      expect(entries.single.product.id, 'prospect|melitta kaffee 500 g');
      expect(entries.single.offer.productId, entries.single.product.id);
    },
  );

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
