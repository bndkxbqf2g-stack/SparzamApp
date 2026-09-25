import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
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
}
