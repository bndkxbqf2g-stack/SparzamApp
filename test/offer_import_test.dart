import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const catalog = [
    Product(
      id: 'milch_35',
      name: 'Vollmilch 3,5 %',
      unit: '1 l',
      group: 'milch',
      aliases: ['milch'],
    ),
    Product(
      id: 'milch_15',
      name: 'Milch 1,5 %',
      unit: '1 l',
      group: 'milch',
      aliases: ['fettarme Milch 1,5 %'],
    ),
    Product(
      id: 'schmand',
      name: 'Schmand',
      unit: '200 g',
      group: 'schmand',
    ),
  ];

  test('specific leaflet product resolves to one catalog identity', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'page-1-item-2',
        productLabel: 'Vollmilch 3,5 %',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 25),
        validUntil: DateTime(2026, 9, 26),
        source: 'leaflet',
        proofRef: 'leaflet:lidl:2026-09-25:p1',
        branchId: 'L-42',
        location: 'Zellingen',
        address: 'Hauptstraße 1, 97225 Zellingen',
      ),
      catalog,
    );

    expect(result.isResolved, isTrue);
    expect(result.product!.id, 'milch_35');
    expect(result.offer!.productId, 'milch_35');
    expect(result.offer!.originalPrice, 1.29);
    expect(result.offer!.offerPrice, 0.99);
    expect(result.offer!.validFrom, DateTime(2026, 9, 25));
    expect(result.offer!.proofRef, 'leaflet:lidl:2026-09-25:p1');
    expect(result.offer!.locationId, 'L-42');
    expect(result.offer!.region, 'Zellingen');
    expect(result.offer!.address, 'Hauptstraße 1, 97225 Zellingen');
    expect(result.offer!.packageAmount, 1);
    expect(result.offer!.packageUnit, 'l');
    expect(result.offer!.unitPrice, closeTo(0.99, 0.00001));
  });

  test('matches a package-suffixed canonical name for KaufDA evidence', () {
    const product = Product(
      id: 'coffee-core-500',
      name: 'Jacobs Kaffee Crema',
      unit: '500 g',
      group: 'kaffee',
    );
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'kaufda-core-package',
        productLabel: 'Jacobs Kaffee Crema 500 g',
        packageSize: '500 g',
        storeName: 'Lidl',
        originalPrice: 6.99,
        offerPrice: 4.99,
        validUntil: DateTime(2026, 10, 17),
        source: 'retailerWebsite',
        sourceAdapter: 'kaufda',
        proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Kaffee',
        branchId: 'lidl_zellingen',
      ),
      const [product],
    );

    expect(result.isResolved, isTrue);
    expect(result.product!.id, product.id);
    expect(result.offer!.packageAmount, 500);
    expect(result.offer!.packageUnit, 'g');
  });

  test('offer without stated regular price stays usable without inventing one', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'sale-only',
        productLabel: 'Schmand',
        storeName: 'EDEKA',
        offerPrice: 0.69,
        validUntil: DateTime(2026, 9, 26),
        source: 'retailerWebsite',
        proofRef: 'https://www.edeka.de/maerkte/example',
      ),
      catalog,
    );

    expect(result.isResolved, isTrue);
    expect(result.offer!.offerPrice, 0.69);
    expect(result.offer!.originalPrice, 0.69);
    expect(result.offer!.originalPriceVerified, isFalse);
  });

  test('does not resolve a catalog variant with a different package size', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'wrong-package',
        productLabel: 'Schmand',
        packageSize: '400 g',
        storeName: 'Lidl',
        offerPrice: 1.49,
        validUntil: DateTime(2026, 9, 30),
        source: 'retailerWebsite',
        proofRef: 'https://example.test/lidl/schmand',
      ),
      catalog,
    );

    expect(result.isResolved, isFalse);
    expect(result.reason, 'package_mismatch');
  });

  test('compares centiliter prospect packages with milliliter catalog units', () {
    const product = Product(
      id: 'sahne',
      name: 'Sahne',
      unit: '200 ml',
      group: 'milch',
    );
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'cl-package',
        productLabel: 'Sahne 20 cl',
        storeName: 'Lidl',
        offerPrice: 0.99,
        validUntil: DateTime(2026, 9, 30),
        source: 'retailerWebsite',
        proofRef: 'https://example.test/lidl/sahne',
      ),
      const [product],
    );

    expect(result.isResolved, isTrue);
    expect(result.product!.id, 'sahne');
  });

  test('keeps ambiguous package ranges unresolved', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'range-package',
        productLabel: 'Schmand 200/180 g',
        storeName: 'Lidl',
        offerPrice: 1.49,
        validUntil: DateTime(2026, 9, 30),
        source: 'retailerWebsite',
        proofRef: 'https://example.test/lidl/schmand-range',
      ),
      catalog,
    );

    expect(result.isResolved, isFalse);
    expect(result.reason, 'package_mismatch');
  });

  test('keeps the KaufDA adapter identity through offer persistence', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'kaufda-1',
        productLabel: 'Schmand 200 g',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.89,
        validUntil: DateTime(2026, 9, 30),
        source: 'retailerWebsite',
        sourceAdapter: 'kaufda',
        capturedAt: DateTime(2026, 9, 24, 8, 30),
        proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Schmand',
        branchId: 'lidl_zellingen',
      ),
      catalog,
    );

    expect(result.isResolved, isTrue);
    expect(result.offer!.source, 'retailerWebsite');
    expect(result.offer!.sourceAdapter, 'kaufda');
    expect(result.offer!.capturedAt, DateTime(2026, 9, 24, 8, 30));
    expect(result.offer!.packageAmount, 200);
    expect(result.offer!.packageUnit, 'g');
    expect(result.offer!.unitPrice, closeTo(4.45, 0.00001));

    final restored = Offer.fromJson(result.offer!.toJson());
    expect(restored.source, 'retailerWebsite');
    expect(restored.sourceAdapter, 'kaufda');
    expect(restored.capturedAt, DateTime(2026, 9, 24, 8, 30));
    expect(restored.packageAmount, 200);
    expect(restored.packageUnit, 'g');
    expect(restored.unitPrice, closeTo(4.45, 0.00001));
  });

  test('regional KaufDA discovery cannot be imported as an exact offer', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'regional-kaufda',
        productLabel: 'Schmand 200 g',
        storeName: 'Lidl',
        offerPrice: 0.89,
        validUntil: DateTime(2026, 9, 30),
        source: 'retailerWebsite',
        sourceAdapter: 'kaufda',
        regionalOnly: false,
        proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Schmand',
      ),
      catalog,
    );

    expect(result.isResolved, isFalse);
    expect(result.offer, isNull);
    expect(result.reason, 'regional_only');
  });

  test('resolved external offer without proof stays untrusted', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'page-without-proof',
        productLabel: 'Schmand',
        storeName: 'Lidl',
        originalPrice: 0.89,
        offerPrice: 0.69,
        validUntil: DateTime(2026, 9, 26),
        source: 'leaflet',
      ),
      catalog,
    );

    expect(result.isResolved, isFalse);
    expect(result.reason, 'missing_proof');
  });

  test('manual import source is case-insensitive and needs no proof', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'manual-case',
        productLabel: 'Schmand',
        storeName: 'Lidl',
        offerPrice: 0.69,
        validUntil: DateTime(2026, 9, 26),
        source: 'MANUAL',
      ),
      catalog,
    );

    expect(result.isResolved, isTrue);
    expect(result.offer!.source, 'MANUAL');
  });

  test('legacy offers without package fields remain readable', () {
    final offer = Offer.fromJson(
      jsonEncode({
        'id': 'legacy-offer',
        'productId': 'schmand',
        'storeName': 'Lidl',
        'originalPrice': 0.89,
        'offerPrice': 0.69,
        'validUntil': '2026-09-30T00:00:00.000',
      }),
    );

    expect(offer.packageAmount, isNull);
    expect(offer.packageUnit, isNull);
    expect(offer.unitPrice, isNull);
  });

  test('unsafe external proof stays untrusted', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'page-with-unsafe-proof',
        productLabel: 'Schmand',
        storeName: 'Lidl',
        originalPrice: 0.89,
        offerPrice: 0.69,
        validUntil: DateTime(2026, 9, 26),
        source: 'leaflet',
        proofRef: 'javascript:alert(1)',
      ),
      catalog,
    );

    expect(result.isResolved, isFalse);
    expect(result.reason, 'missing_proof');
  });

  test('generic leaflet identity stays unresolved when variants are ambiguous', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'milk-generic',
        productLabel: 'Milch',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.99,
        validUntil: DateTime(2026, 9, 26),
      ),
      catalog,
    );

    expect(result.isResolved, isFalse);
    expect(result.reason, 'ambiguous_identity');
  });

  test('unknown product is not invented during import', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'unknown',
        productLabel: 'Mystery Drink',
        storeName: 'Lidl',
        originalPrice: 2.49,
        offerPrice: 1.99,
        validUntil: DateTime(2026, 9, 26),
      ),
      catalog,
    );

    expect(result.isResolved, isFalse);
    expect(result.reason, 'unknown_identity');
  });

  test('invalid price evidence is rejected', () {
    final result = resolveOfferImport(
      OfferImportRecord(
        sourceId: 'bad',
        productLabel: 'Schmand',
        storeName: 'Lidl',
        originalPrice: 0.79,
        offerPrice: 0.89,
        validUntil: DateTime(2026, 9, 26),
      ),
      catalog,
    );

    expect(result.reason, 'invalid_price');
  });
  test('keeps source-backed prospect widget keys unique per market', () {
    final lidl = OfferImportRecord(
      sourceId: 'shared-source-id',
      productLabel: 'Butter 250 g',
      storeName: 'Lidl',
      offerPrice: 1.29,
      validUntil: DateTime(2026, 10, 17),
    );
    final netto = OfferImportRecord(
      sourceId: 'shared-source-id',
      productLabel: 'Butter 250 g',
      storeName: 'Netto',
      offerPrice: 1.29,
      validUntil: DateTime(2026, 10, 17),
    );

    expect(prospectOfferRecordKey(lidl), isNot(prospectOfferRecordKey(netto)));
  });

  test('fallback prospect widget keys distinguish source-id-free records', () {
    final first = OfferImportRecord(
      sourceId: '',
      productLabel: 'Milch 1 l',
      storeName: 'Lidl',
      offerPrice: 0.99,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      brochureId: 'kw42',
      brochurePage: 3,
    );
    final second = OfferImportRecord(
      sourceId: '',
      productLabel: 'Milch 1 l',
      storeName: 'Lidl',
      offerPrice: 1.09,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      brochureId: 'kw42',
      brochurePage: 3,
    );

    expect(prospectOfferRecordKey(first), isNot(prospectOfferRecordKey(second)));
    expect(prospectOfferRecordKey(first), isNotEmpty);
  });

}

