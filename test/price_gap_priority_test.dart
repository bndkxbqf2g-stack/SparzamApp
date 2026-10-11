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

  test('priorisiert bekannte Wiederkäufe vor der Listenmenge', () {
    const frequent = Product(
      id: 'frequent',
      name: 'Hafermilch',
      unit: '1 l',
      group: 'milch',
    );
    const occasional = Product(
      id: 'occasional',
      name: 'Kokosdrink',
      unit: '1 l',
      group: 'milch',
    );

    final gaps = prioritizePriceGaps(
      [
        ListItem(product: occasional, quantity: 4),
        ListItem(product: frequent, quantity: 1),
      ],
      marketCount: 2,
      purchaseCountFor: (item) => item.product.id == 'frequent' ? 6 : 1,
    );

    expect(gaps.map((gap) => gap.item.product.id), ['frequent', 'occasional']);
    expect(gaps.first.purchaseCount, 6);
    expect(gaps.first.detailLabel, contains('bisher 6 Käufe'));
  });

  test('priorisiert ein bekannt hohes historisches Preisniveau', () {
    const expensive = Product(
      id: 'expensive',
      name: 'Kaffee',
      unit: '500 g',
      group: 'kaffee',
    );
    const affordable = Product(
      id: 'affordable',
      name: 'Tee',
      unit: '40 Beutel',
      group: 'tee',
    );

    final gaps = prioritizePriceGaps(
      [
        ListItem(product: affordable, quantity: 4),
        ListItem(product: expensive, quantity: 1),
      ],
      marketCount: 2,
      historicalPriceLevelFor: (item) =>
          item.product.id == 'expensive' ? 8.50 : 1.20,
    );

    expect(gaps.map((gap) => gap.item.product.id), ['expensive', 'affordable']);
    expect(gaps.first.historicalPriceLevel, 8.50);
    expect(gaps.first.detailLabel, contains('Historie-Median 8,50 €'));
  });

  test('berechnet die Datenlückenrelevanz nur aus bekannten Signalen', () {
    final item = ListItem(product: staple, quantity: 2);
    final gaps = prioritizePriceGaps(
      [item],
      marketCount: 4,
      missingMarketCountFor: (_) => 3,
      purchaseCountFor: (_) => 2,
      historicalPriceLevelFor: (_) => 4.50,
    );

    // 3/4 uncovered markets × 2 requested units × 2 purchases × 4.50 €
    // historical basis. The result is an index, never a route price.
    expect(gaps.single.dataGapScore, closeTo(13.5, 0.000001));
  });

  test('fehlende Historie erhält eine neutrale Score-Basis', () {
    final gaps = prioritizePriceGaps(
      [ListItem(product: staple, quantity: 2)],
      marketCount: 2,
      purchaseCountFor: (_) => 3,
    );

    expect(gaps.single.historicalPriceLevel, isNull);
    expect(gaps.single.dataGapScore, 6);
  });

  test('kombiniert die bekannten Signale für die Reihenfolge', () {
    const highImpact = Product(
      id: 'high-impact',
      name: 'Kaffee',
      unit: '500 g',
      group: 'kaffee',
    );
    const frequent = Product(
      id: 'frequent-only',
      name: 'Tee',
      unit: '40 Beutel',
      group: 'tee',
    );

    final gaps = prioritizePriceGaps(
      [
        ListItem(product: frequent, quantity: 1),
        ListItem(product: highImpact, quantity: 3),
      ],
      marketCount: 4,
      missingMarketCountFor: (_) => 3,
      purchaseCountFor: (item) =>
          item.product.id == 'frequent-only' ? 6 : 2,
      historicalPriceLevelFor: (item) =>
          item.product.id == 'high-impact' ? 4.0 : 1.0,
    );

    // Kaffee: 3/4 × 3 × 2 × 4 = 18. Tee: 3/4 × 1 × 6 × 1 = 4.5.
    expect(gaps.map((gap) => gap.item.product.id), [
      'high-impact',
      'frequent-only',
    ]);
  });
}
