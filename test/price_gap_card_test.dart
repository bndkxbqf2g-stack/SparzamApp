import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/price_gaps/price_gap_card.dart';
import 'package:sparzamapp/features/price_gaps/price_gap_priority.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  testWidgets('führt von einer Datenlücke direkt zur Preiseingabe', (
    tester,
  ) async {
    const product = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
      isStaple: true,
    );
    final gap = PriceGapPriority(
      item: ListItem(product: product),
      missingMarketCount: 2,
      marketCount: 2,
    );
    PriceGapPriority? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceGapCard(
            gaps: [gap],
            onResolveGap: (value) async => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Produkt oder Preis ergänzen'), findsOneWidget);
    await tester.tap(find.text('Produkt oder Preis ergänzen'));
    await tester.pump();

    expect(selected?.item.product.id, 'milk');
  });
}
