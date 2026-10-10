import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_search_results.dart';
import 'package:sparzamapp/features/shopping_list/shopping_suggestions.dart';
import 'package:sparzamapp/features/offers/prospect_price_statistics.dart';
import 'package:sparzamapp/models/price_observation.dart';
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

  testWidgets('shopping search labels the current price recommendation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingSearchResults(
            query: 'Milch',
            suggestions: const [product],
            relatedInterpretations: const [],
            preferredProductByGroup: const {},
            recentPurchases: const [],
            recommendedProductId: product.id,
            onAdd: (_) {},
            onAddCustom: () {},
          ),
        ),
      ),
    );

    expect(find.text('Milch 1,5 % · Empfehlung'), findsOneWidget);
  });

  testWidgets('known family fallback opens concrete product selection', (
    tester,
  ) async {
    var chooserOpened = false;
    var customAdded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingSearchResults(
            query: 'Milch',
            suggestions: const [product],
            relatedInterpretations: const [],
            preferredProductByGroup: const {},
            recentPurchases: const [],
            onChooseKnownProduct: () => chooserOpened = true,
            onAdd: (_) {},
            onAddCustom: () => customAdded = true,
          ),
        ),
      ),
    );

    expect(find.text('„Milch“ konkret auswählen'), findsOneWidget);
    expect(find.text('Varianten und belegte Preise auswählen.'), findsOneWidget);
    await tester.tap(find.text('„Milch“ konkret auswählen'));

    expect(chooserOpened, isTrue);
    expect(customAdded, isFalse);
  });

  testWidgets('unknown free text remains a custom list item', (tester) async {
    var customAdded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingSearchResults(
            query: 'Sonderwunsch',
            suggestions: const [],
            relatedInterpretations: const [],
            preferredProductByGroup: const {},
            recentPurchases: const [],
            onAdd: (_) {},
            onAddCustom: () => customAdded = true,
          ),
        ),
      ),
    );

    expect(find.text('„Sonderwunsch“ hinzufügen'), findsOneWidget);
    await tester.tap(find.text('„Sonderwunsch“ hinzufügen'));

    expect(customAdded, isTrue);
  });

  testWidgets('shopping search labels learned leaflet prices as historical', (
    tester,
  ) async {
    final summary = ProspectPriceHistorySummary(
      productId: product.id,
      storeName: 'Netto',
      medianPrice: 0.85,
      latestValidUntil: DateTime(2026, 9, 27),
      kind: PriceObservationKind.offer,
      observationCount: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingSearchResults(
            query: 'Milch',
            suggestions: const [product],
            relatedInterpretations: const [],
            preferredProductByGroup: const {},
            recentPurchases: const [],
            priceHintFor: (value) => shoppingSuggestionPriceForProduct(
              value,
              prospectPriceHistory: {product.id: summary},
              now: DateTime(2026, 9, 30),
            )?.displayLabel,
            onAdd: (_) {},
            onAddCustom: () {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Früheres Angebot (Median) Netto 0,85 €'),
      findsOneWidget,
    );
    expect(find.textContaining('Stand 27.09.2026'), findsOneWidget);
  });

  testWidgets('recalled receipt label is visibly marked for review', (
    tester,
  ) async {
    const recalled = Product(
      id: 'receipt_suggestion_milk',
      name: 'H-Milch',
      unit: 'Packung',
      group: 'milch',
      aliases: ['K.H-Milch'],
    );
    Product? added;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShoppingSearchResults(
              query: 'K.H-Milch',
              suggestions: const [recalled],
              relatedInterpretations: const [],
              preferredProductByGroup: const {},
              recentPurchases: const [],
              priceHintFor: (_) => null,
              onAdd: (value) => added = value,
              onAddCustom: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Früher gekauft · Sorte und Packung prüfen'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('H-Milch'));
    expect(added, recalled);
  });

  testWidgets('automatic receipt product is visibly marked for review', (
    tester,
  ) async {
    const provisional = Product(
      id: 'receipt_auto_specialitaet',
      name: 'Spezialität unbekannt',
      unit: 'Stück',
      group: 'sonstiges',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingSearchResults(
            query: 'Spezialität',
            suggestions: const [provisional],
            relatedInterpretations: const [],
            preferredProductByGroup: const {},
            recentPurchases: const [],
            onAdd: (_) {},
            onAddCustom: () {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Früher gekauft · Sorte und Packung prüfen'),
      findsOneWidget,
    );
  });
}
