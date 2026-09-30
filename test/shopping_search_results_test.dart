import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_search_results.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const product = Product(
    id: 'milk-15',
    name: 'Milch 1,5 %',
    unit: '1 l',
    group: 'milch',
  );

  testWidgets('shopping search shows price and adds the selected product', (
    tester,
  ) async {
    Product? added;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShoppingSearchResults(
              query: 'Milch',
              suggestions: const [product],
              relatedInterpretations: const [],
              preferredProductByGroup: const {},
              recentPurchases: const [],
              priceHintFor: (_) => 'Angebot ALDI Süd 0,95 € · bis 02.10.2026',
              onAdd: (value) => added = value,
              onAddCustom: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Angebot ALDI Süd 0,95 €'), findsOneWidget);
    await tester.tap(find.text('Milch 1,5 %'));
    expect(added, product);
  });
}
