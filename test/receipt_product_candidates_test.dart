import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_product_candidates.dart';
import 'package:sparzamapp/features/catalog/product_match_candidates.dart';

import 'package:sparzamapp/models/product.dart';

void main() {
  const catalog = [
    Product(
      id: 'milk',
      name: 'H-Milch',
      unit: '1 l',
      group: 'milch',
      aliases: ['Milch'],
    ),
    Product(
      id: 'oat',
      name: 'Haferdrink',
      unit: '1 l',
      group: 'milch',
      aliases: ['Hafer Milch'],
    ),
    Product(
      id: 'bread',
      name: 'Vollkornbrot',
      unit: '500 g',
      group: 'brot',
    ),
  ];

  test('returns explicit name and alias candidates for an unresolved line', () {
    final candidates = receiptProductCandidates(
      rawLabel: 'Milch',
      products: catalog,
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.product.id, 'milk');
    expect(candidates.single.relation, CandidateRelation.relatedName);
  });

  test('does not present broad category matches as receipt identities', () {
    final candidates = receiptProductCandidates(
      rawLabel: 'milch',
      products: const [
        Product(id: 'milk', name: 'Milch', unit: '1 l', group: 'milch'),
      ],
    );

    expect(candidates, isEmpty);
  });

  test('limits the visible suggestion set and keeps empty input safe', () {
    expect(
      receiptProductCandidates(
        rawLabel: 'Brot',
        products: catalog,
        limit: 1,
      ),
      hasLength(1),
    );
    expect(
      receiptProductCandidates(rawLabel: '  ', products: catalog),
      isEmpty,
    );
  });
}
