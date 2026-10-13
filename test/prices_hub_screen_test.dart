import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/catalog/prices_hub_screen.dart';
import 'package:sparzamapp/features/price_gaps/price_gap_priority.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  testWidgets('Preise zeigt aktuelle Listenabdeckung und Markt-Hinweis', (
    tester,
  ) async {
    const product = Product(
      id: 'price-hub-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );
    final openedList = <bool>[];
    final openedRoute = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Open Prices · max. 60 Tage',
            shoppingList: [ListItem(product: product)],
            marketPrices: [
              MarketPrice(
                productId: product.id,
                storeName: 'Lidl',
                price: 1.19,
                updatedAt: DateTime.now(),
                source: MarketPriceSource.manual,
              ),
            ],
            enabledStoreNames: const ['Lidl'],
            onOpenList: () => openedList.add(true),
            onOpenRoute: () => openedRoute.add(true),
          ),
        ),
      ),
    );

    expect(find.text('Preisabdeckung deiner Liste'), findsOneWidget);
    expect(find.text('1 von 1 Positionen mit aktuellem Marktpreis'), findsOneWidget);
    expect(find.textContaining('Lidl'), findsOneWidget);
    expect(find.text('1,19 €'), findsOneWidget);

    await tester.tap(find.text('Liste öffnen'));
    await tester.tap(find.text('Route prüfen'));
    expect(openedList, [true]);
    expect(openedRoute, [true]);
  });

  testWidgets('zeigt Herkunft und Datum eines regulären Prospektpreises', (
    tester,
  ) async {
    const product = Product(
      id: 'price-hub-prospect-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Prospektpreise',
            shoppingList: [ListItem(product: product)],
            marketPrices: [
              MarketPrice(
                productId: product.id,
                storeName: 'Lidl',
                price: 1.29,
                updatedAt: DateTime(2026, 10, 13),
                source: MarketPriceSource.prospect,
              ),
            ],
            enabledStoreNames: const ['Lidl'],
            now: DateTime(2026, 10, 13),
          ),
        ),
      ),
    );

    final card = find.byKey(
      const ValueKey('price-comparison-price-hub-prospect-milk'),
    );
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.textContaining('Prospektpreis vom 13.10.2026'), findsOneWidget);
    expect(find.textContaining('Preisalter: heute'), findsOneWidget);
  });

  testWidgets('öffnet den Marktvergleich je Listenposition', (tester) async {
    const product = Product(
      id: 'price-hub-matrix-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Eigene Preise',
            shoppingList: [ListItem(product: product)],
            marketPrices: [
              MarketPrice(
                productId: product.id,
                storeName: 'Lidl',
                price: 1.19,
                updatedAt: DateTime(2026, 10, 13),
                source: MarketPriceSource.manual,
              ),
            ],
            enabledStoreNames: const ['Lidl', 'ALDI Süd'],
            now: DateTime(2026, 10, 13),
          ),
        ),
      ),
    );

    expect(find.text('Marktvergleich deiner Liste'), findsOneWidget);
    final card = find.byKey(
      const ValueKey('price-comparison-price-hub-matrix-milk'),
    );
    expect(card, findsOneWidget);
    expect(find.text('1/2 Märkte aktuell'), findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Lidl'), findsOneWidget);
    expect(find.text('ALDI Süd'), findsOneWidget);
    expect(find.text('1,19 €'), findsNWidgets(2));
    expect(find.text('Kein aktueller, vergleichbarer Preisbeleg'), findsOneWidget);
  });

  testWidgets('Preise kennzeichnet fehlende aktuelle Preise', (tester) async {
    const milk = Product(
      id: 'price-hub-milk-missing',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );
    const coffee = Product(
      id: 'price-hub-coffee-missing',
      name: 'Kaffee',
      unit: '500 g',
      group: 'Kaffee',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Nur eigene Preise',
            shoppingList: [
              ListItem(product: milk),
              ListItem(product: coffee),
            ],
            enabledStoreNames: const ['Lidl'],
          ),
        ),
      ),
    );

    expect(find.text('0 von 2 Positionen mit aktuellem Marktpreis'), findsOneWidget);
    expect(find.text('2 Positionen ohne aktuellen Preis'), findsOneWidget);
    expect(find.text('2 unbekannt'), findsOneWidget);
  });

  testWidgets('lädt große Marktvergleiche schrittweise', (tester) async {
    final items = List<ListItem>.generate(
      13,
      (index) => ListItem(
        product: Product(
          id: 'price-hub-progress-$index',
          name: 'Produkt $index',
          unit: '1 Stück',
          group: 'Test',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Testpreise',
            shoppingList: items,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('price-comparison-price-hub-progress-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('price-comparison-price-hub-progress-12')),
      findsNothing,
    );

    final loadMore = find.byKey(
      const ValueKey('price-comparisons-load-more'),
    );
    expect(loadMore, findsOneWidget);
    tester.widget<OutlinedButton>(loadMore).onPressed!.call();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('price-comparison-price-hub-progress-12')),
      findsOneWidget,
    );
  });

  testWidgets('öffnet für fehlende Preise direkt die Auflösung', (tester) async {
    const product = Product(
      id: 'price-hub-gap-milk',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );
    final resolved = <PriceGapPriority>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PricesHubScreen(
            onOpenCatalog: () {},
            onOpenSettings: () {},
            summary: 'Nur eigene Preise',
            shoppingList: [ListItem(product: product)],
            enabledStoreNames: const ['Lidl', 'ALDI Süd'],
            onResolvePriceGap: (gap) async => resolved.add(gap),
          ),
        ),
      ),
    );

    final card = find.byKey(
      const ValueKey('price-comparison-price-hub-gap-milk'),
    );
    await tester.tap(card);
    await tester.pumpAndSettle();

    final action = find.byKey(
      const ValueKey('resolve-price-gap-price-hub-gap-milk'),
    );
    expect(action, findsOneWidget);
    tester.widget<TextButton>(action).onPressed!.call();
    await tester.pump();

    expect(resolved, hasLength(1));
    expect(resolved.single.item.product.id, product.id);
    expect(resolved.single.missingMarketCount, 2);
    expect(resolved.single.marketCount, 2);
  });
}
