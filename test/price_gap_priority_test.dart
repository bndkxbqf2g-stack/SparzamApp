import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/price_gaps/price_gap_priority.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const staple = Product(
    id: 'milk',
    name: 'Milch',
    unit: '1 l',
    group: 'milch',
    isStaple: true,
  );
  const otherStaple = Product(
    id: 'bread',
    name: 'Brot',
    unit: '500 g',
    group: 'brot',
    isStaple: true,
  );
  const unknown = Product(
    id: 'unknown',
    name: 'Zubehör',
    unit: 'Stück',
    group: 'custom',
  );

  test('priorisiert fehlende Märkte, Grundbedarf und dann Listenmenge', () {
    final gaps = prioritizePriceGaps(
      [
        ListItem(product: unknown, quantity: 4),
        ListItem(product: otherStaple, quantity: 1),
        ListItem(product: staple, quantity: 2),
      ],
      marketCount: 6,
      missingMarketCountFor: (item) => item.product.id == 'bread' ? 5 : 6,
    );

    expect(gaps.map((gap) => gap.item.product.id), [
      'milk',
      'unknown',
      'bread',
    ]);
    expect(gaps.first.marketLabel, '6 von 6 Märkten ohne Preis');
    expect(
      gaps.first.detailLabel,
      'Menge ×2 · 6 von 6 Märkten ohne Preis · Grundbedarf',
    );
  });

  test('gleiche Signale bleiben alphabetisch deterministisch', () {
    const alpha = Product(
      id: 'alpha',
      name: 'Alpha',
      unit: 'Stück',
      group: 'custom',
    );
    const beta = Product(
      id: 'beta',
      name: 'Beta',
      unit: 'Stück',
      group: 'custom',
    );

    final gaps = prioritizePriceGaps([
      ListItem(product: beta),
      ListItem(product: alpha),
    ], marketCount: 1);

    expect(gaps.map((gap) => gap.item.product.id), ['alpha', 'beta']);
    expect(gaps.first.knownMarketCount, 0);
  });
}
