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
}
