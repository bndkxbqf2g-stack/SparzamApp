import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_match_candidates.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const catalog = [
    Product(id: 'rye', name: 'Roggenbrot', group: 'brot', unit: '500 g',
        ean: '1234567890123', brand: 'Bäcker', aliases: ['Roggenlaib']),
    Product(id: 'toast', name: 'Toast', group: 'brot', unit: '500 g',
        brand: 'Andere Marke'),
    Product(id: 'coffee', name: 'Kaffee', group: 'kaffee', unit: '500 g',
        brand: 'Jacobs'),
  ];

  test('general bread wish yields category suggestions, not identity', () {
    final matches = suggestProducts(
        const ProductQuery(label: 'Brot'), catalog);
    expect(matches.map((m) => m.product.id), containsAll(['rye', 'toast']));
    expect(matches.every((m) =>
        m.relation == CandidateRelation.categoryOnly), isTrue);
    expect(matches.every((m) => m.cautions.isNotEmpty), isTrue);
  });

  test('a hard brand preference excludes otherwise similar products', () {
    final matches = suggestProducts(
        const ProductQuery(label: 'Brot', requiredBrand: 'Bäcker'),
        catalog);
    expect(matches.map((m) => m.product.id), ['rye']);
  });

  test('alias is a suggestion while a barcode gets its own class', () {
    final alias = suggestProducts(
        const ProductQuery(label: 'Roggenlaib'), catalog);
    expect(alias.single.relation, CandidateRelation.relatedName);
    final code = suggestProducts(
        const ProductQuery(label: 'unbekannt', ean: '1234567890123'),
        catalog);
    expect(code.single.relation, CandidateRelation.sameBarcode);
  });

  test('barcode candidates use the same canonical form as scanner input', () {
    final code = suggestProducts(
      const ProductQuery(label: 'unbekannt', ean: '123-456789012'),
      [
        const Product(
          id: 'upc',
          name: 'UPC-Produkt',
          group: 'vorrat',
          unit: '1 Stück',
          ean: '0123456789012',
        ),
      ],
    );
    expect(code.single.relation, CandidateRelation.sameBarcode);
  });
  test('abbreviated milk labels yield explicit identity candidates', () {
    final matches = suggestProducts(
      const ProductQuery(label: 'K.H-Milch'),
      [
        const Product(
          id: 'milk-15',
          name: 'H-Milch 1,5 %',
          unit: '1 l',
          group: 'milch',
        ),
        const Product(
          id: 'milk-35',
          name: 'H-Milch 3,5 %',
          unit: '1 l',
          group: 'milch',
        ),
      ],
    );

    expect(matches.map((candidate) => candidate.product.id), [
      'milk-15',
      'milk-35',
    ]);
    expect(
      matches.every(
        (candidate) =>
            candidate.relation == CandidateRelation.relatedName &&
            candidate.cautions.contains('Produktidentität nicht bestätigt'),
      ),
      isTrue,
    );
  });

  test('identity candidates keep fresh tomato variants away from passata', () {
    final matches = suggestProducts(
      const ProductQuery(label: 'Rispen Tomaten'),
      [
        const Product(
          id: 'tomate-rispe',
          name: 'Rispentomaten',
          unit: '500 g',
          group: 'obst_gemuese',
        ),
        const Product(
          id: 'passata',
          name: 'Passierte Tomaten',
          unit: '500 g',
          group: 'vorrat',
        ),
      ],
    );

    expect(matches.map((candidate) => candidate.product.id), ['tomate-rispe']);
    expect(
      matches.single.reasons,
      contains('Kompatible Produktidentität'),
    );
  });

}
