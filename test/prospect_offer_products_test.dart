import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_offer_products.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  final current = DateTime(2026, 9, 30);

  test('cached feed merge keeps manual offers and replaces automatic imports', () {
    final manual = Offer(
      id: 'manual-milk',
      productId: 'milk',
      storeName: 'Netto',
      originalPrice: 1.29,
      offerPrice: 1.29,
      validUntil: DateTime(2026, 10, 2),
    );
    final staleImport = Offer(
      id: 'import|retailerWebsite|old|milk',
      productId: 'milk',
      storeName: 'Netto',
      originalPrice: 1.29,
      offerPrice: 0.99,
      validUntil: DateTime(2026, 9, 29),
      source: 'retailerWebsite',
    );
    final currentImport = Offer(
      id: 'import|retailerWebsite|current|milk',
      productId: 'milk',
      storeName: 'Netto',
      originalPrice: 1.29,
      offerPrice: 0.89,
      validUntil: DateTime(2026, 10, 2),
      source: 'retailerWebsite',
    );
    final merged = mergeTransientProspectOffers(
      existingOffers: [manual, staleImport],
      importedOffers: [
        ProspectOfferProduct(
          const Product(
            id: 'milk',
            name: 'Milch 1 l',
            unit: '1 l',
            group: 'milch',
          ),
          currentImport,
        ),
      ],
    );

    expect(merged.map((offer) => offer.id), [
      'manual-milk',
      'import|retailerWebsite|current|milk',
    ]);
    expect(merged.singleWhere((offer) => offer.id == 'manual-milk'), manual);
    expect(
      merged.singleWhere(
        (offer) => offer.id == 'import|retailerWebsite|current|milk',
      ).offerPrice,
      0.89,
    );
  });

  test('keeps same source item in separate exact branches', () {
    const milk = Product(
      id: 'milk-1l',
      name: 'Milch 1 l',
      unit: '1 l',
      group: 'milch',
    );
    final entries = prospectOfferProducts(
      records: [
        for (final branch in ['lidl-a', 'lidl-b'])
          OfferImportRecord(
            sourceId: 'same-leaflet-item',
            productLabel: 'Milch 1 l',
            storeName: 'Lidl',
            branchId: branch,
            location: branch == 'lidl-a' ? 'Thüngersheim' : 'Würzburg',
            offerPrice: branch == 'lidl-a' ? 0.89 : 0.99,
            validUntil: DateTime(2026, 10, 2),
            source: 'retailerWebsite',
            proofRef: 'https://example.test/lidl/same-leaflet-item',
          ),
      ],
      catalogProducts: const [milk],
      now: current,
    );

    expect(entries, hasLength(2));
    expect(entries.map((entry) => entry.offer.id).toSet(), hasLength(1));
    expect(
      entries.map((entry) => entry.offer.locationId),
      containsAll(['lidl-a', 'lidl-b']),
    );

    final merged = mergeTransientProspectOffers(
      existingOffers: const [],
      importedOffers: entries,
    );
    expect(merged, hasLength(2));
    expect(
      merged.map((offer) => offer.locationId),
      containsAll(['lidl-a', 'lidl-b']),
    );
  });
  test('ambiguous verified offer gets an explicit-label review product', () {
    final record = OfferImportRecord(
      sourceId: 'ambiguous-1',
      productLabel: 'Milch 1 l',
      storeName: 'Lidl',
      offerPrice: 0.99,
      validUntil: DateTime(2026, 10, 2),
      source: 'leaflet',
      proofRef: 'https://example.test/lidl/ambiguous-1',
    );

    const catalog = [
      Product(
        id: 'milk-a',
        name: 'Milch 1 l',
        unit: '1 l',
        group: 'milch',
      ),
      Product(
        id: 'milk-b',
        name: 'Milch 1 l',
        unit: '1 l',
        group: 'milch',
      ),
    ];
    final product = addableProductForProspectOffer(
      record,
      catalog,
      catalogIndex: OfferImportCatalogIndex(catalog),
    );
    final reviewProduct = manualProductForProspectOffer(record);

    expect(product, isNull);
    expect(reviewProduct, isNotNull);
    expect(reviewProduct!.id, startsWith('prospect|'));
    expect(reviewProduct.name, 'Milch 1 l');
    expect(reviewProduct.unit, '1 l');
  });

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
          address: 'Am Markt 1, 97291 Thüngersheim',
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
    expect(entries.single.offer.address, 'Am Markt 1, 97291 Thüngersheim');
  });

  test(
    'verified unknown offer is addable from a prospect without remapping it',
    () {
      final product = addableProductForProspectOffer(
        OfferImportRecord(
          sourceId: 'unknown-1',
          productLabel: 'Eigenmarke Haferdrink 1 l',
          storeName: 'Lidl',
          offerPrice: 0.99,
          validUntil: DateTime(2026, 10, 2),
          source: 'leaflet',
          proofRef: 'https://example.test/lidl/unknown-1',
        ),
        const <Product>[],
      );

      expect(product, isNotNull);
      expect(product!.name, 'Eigenmarke Haferdrink 1 l');
      expect(product.id, startsWith('prospect|'));
    },
  );

  test('unproven offer cannot be transferred to the shopping list', () {
    final product = addableProductForProspectOffer(
      OfferImportRecord(
        sourceId: 'unproven-1',
        productLabel: 'Haferdrink 1 l',
        storeName: 'Lidl',
        offerPrice: 0.99,
        validUntil: DateTime(2026, 10, 2),
        source: 'leaflet',
      ),
      const <Product>[],
    );

    expect(product, isNull);
  });

  test('regional-only source evidence is never routeable', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'regional-only',
          productLabel: 'Butter 250 g',
          storeName: 'Lidl',
          offerPrice: 1.49,
          validUntil: DateTime(2026, 10, 17),
          source: 'retailerWebsite',
          sourceAdapter: 'kaufda',
          regionalOnly: false,
          proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Butter',
        ),
      ],
      catalogProducts: const <Product>[],
      now: DateTime(2026, 10, 12),
    );

    expect(entries, isEmpty);
  });

  test('regional prospect can be list-only but never routeable', () {
    final record = OfferImportRecord(
      sourceId: 'regional-list-only',
      productLabel: 'Butter 250 g',
      storeName: 'Lidl',
      offerPrice: 1.49,
      validUntil: DateTime(2026, 10, 17),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      regionalOnly: true,
      proofRef: 'https://example.test/kaufda/butter',
    );

    final product = listOnlyProductForRegionalProspectOffer(
      record,
      const <Product>[],
    );
    final entries = prospectOfferProducts(
      records: [record],
      catalogProducts: const <Product>[],
      now: DateTime(2026, 10, 12),
    );

    expect(product, isNotNull);
    expect(product!.name, 'Butter 250 g');
    expect(entries, isEmpty);
  });

  test('unsafe proof cannot be transferred to the shopping list', () {
    final product = addableProductForProspectOffer(
      OfferImportRecord(
        sourceId: 'unsafe-proof-1',
        productLabel: 'Haferdrink 1 l',
        storeName: 'Lidl',
        offerPrice: 0.99,
        validUntil: DateTime(2026, 10, 2),
        source: 'leaflet',
        proofRef: 'javascript:alert(1)',
      ),
      const <Product>[],
    );

    expect(product, isNull);
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

  test('keeps variant package ranges without a guessed quantity', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'variant-range',
          productLabel: 'Milka Tafelschokolade Je 100/95/90 g',
          storeName: 'Lidl',
          offerPrice: 1.11,
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/lidl/range',
        ),
      ],
      catalogProducts: const <Product>[],
      now: current,
    );

    expect(entries.single.product.packageAmount, isNull);
    expect(entries.single.product.packageUnit, isNull);
    expect(entries.single.product.unit, 'Packung');
  });

  test('understands count packs as pieces', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'count-pack',
          productLabel: 'Kiwi Gold je 3er-Schale',
          storeName: 'PENNY',
          offerPrice: 1,
          validUntil: DateTime(2026, 10, 2),
          source: 'retailerWebsite',
          proofRef: 'https://example.test/penny/kiwi',
        ),
      ],
      catalogProducts: const <Product>[],
      now: current,
    );

    expect(entries.single.product.packageAmount, 3);
    expect(entries.single.product.packageUnit, 'Stück');
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

  test('uses KaufDA package metadata for exact catalog identity', () {
    const coffee = Product(
      id: 'coffee-500',
      name: 'Kaffee',
      unit: '500 g',
      group: 'kaffee',
      packageAmount: 500,
      packageUnit: 'g',
    );
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'kaufda-coffee',
          productLabel: 'Kaffee',
          packageSize: '500 g',
          priceByBaseUnit: '4,98 €/kg',
          storeName: 'Lidl',
          offerPrice: 2.49,
          validUntil: DateTime(2026, 10, 17),
          source: 'retailerWebsite',
          sourceAdapter: 'kaufda',
          capturedAt: DateTime(2026, 10, 12, 7, 30),
          proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Kaffee',
          branchId: 'lidl_zellingen',
        ),
      ],
      catalogProducts: const [coffee],
      now: DateTime(2026, 10, 12),
    );

    expect(entries, hasLength(1));
    expect(entries.single.product.id, coffee.id);
    expect(entries.single.offer.sourceAdapter, 'kaufda');
    expect(entries.single.offer.capturedAt, DateTime(2026, 10, 12, 7, 30));
    expect(entries.single.offer.packageAmount, 500);
    expect(entries.single.offer.packageUnit, 'g');
    expect(entries.single.offer.unitPrice, closeTo(4.98, 0.00001));
    expect(entries.single.product.packageAmount, 500);
    expect(entries.single.offer.productId, coffee.id);
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

  test('canonicalizes source variants for addable prospect offers', () {
    final entries = prospectOfferProducts(
      records: [
        OfferImportRecord(
          sourceId: 'canonical-product-source',
          productLabel: 'Schmand 200 g',
          storeName: 'Lidl',
          offerPrice: 0.69,
          validUntil: DateTime(2026, 10, 2),
          source: 'retailer_website',
          proofRef: 'https://example.test/lidl/canonical-product-source',
        ),
      ],
      catalogProducts: const [
        Product(
          id: 'schmand-canonical',
          name: 'Schmand 200 g',
          unit: '200 g',
          group: 'schmand',
        ),
      ],
      now: current,
    );

    expect(entries, hasLength(1));
    expect(entries.single.offer.source, 'retailerWebsite');
    expect(
      entries.single.offer.id,
      'import|retailerWebsite|canonical-product-source|schmand-canonical',
    );
  });
}
