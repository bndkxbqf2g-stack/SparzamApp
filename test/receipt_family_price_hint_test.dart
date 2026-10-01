import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/receipt_family_price_hint.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_price_stat.dart';

void main() {
  const product = Product(
    id: 'schmand',
    name: 'Schmand',
    unit: '200 g',
    group: 'milchprodukte',
  );

  ReceiptPriceStat stat({
    required String store,
    required double price,
    required DateTime latestAt,
  }) => ReceiptPriceStat(
    familyKey: 'schmand',
    storeName: store,
    latestPrice: price,
    latestAt: latestAt,
    observationCount: 2,
    medianPrice: price,
    comparable: true,
    priceBasis: 'Stück',
  );

  testWidgets('kennzeichnet einen Bonmedian als historischen Hinweis', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptFamilyPriceHint(
            product: product,
            stats: [
              stat(
                store: 'Kaufland',
                price: 0.79,
                latestAt: DateTime(2026, 9, 20),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Bon-Median (historisch)'), findsOneWidget);
    expect(find.textContaining('Stand 20.09.2026'), findsOneWidget);
  });

  testWidgets('kennzeichnet mehrere Marktmediane gemeinsam als historisch', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptFamilyPriceHint(
            product: product,
            stats: [
              stat(
                store: 'Kaufland',
                price: 0.79,
                latestAt: DateTime(2026, 9, 20),
              ),
              stat(store: 'Lidl', price: 0.69, latestAt: DateTime(2026, 9, 18)),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Bon-Mediane (historisch)'), findsOneWidget);
  });
}
