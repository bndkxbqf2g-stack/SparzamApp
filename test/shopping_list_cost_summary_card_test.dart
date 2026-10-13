import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/shopping_list/shopping_list_cost_summary_card.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  testWidgets('trennt aktuelle, historische und unbekannte Preise', (
    tester,
  ) async {
    var openedRoute = false;
    final current = const Product(
      id: 'milk-15',
      name: 'Vollmilch 1,5 % 1 l',
      unit: '1 l',
      group: 'Milchprodukte',
    );
    final historical = const Product(
      id: 'butter-250',
      name: 'Butter 250 g',
      unit: '250 g',
      group: 'Milchprodukte',
    );
    final unknown = const Product(
      id: 'coffee-500',
      name: 'Kaffee 500 g',
      unit: '500 g',
      group: 'Kaffee & Snacks',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingListCostSummaryCard(
            items: [
              ListItem(product: current),
              ListItem(product: historical),
              ListItem(product: unknown),
            ],
            marketPrices: [
              MarketPrice(
                productId: current.id,
                storeName: 'Lidl',
                price: 2.50,
                updatedAt: DateTime(2026, 10, 13),
              ),
              MarketPrice(
                productId: historical.id,
                storeName: 'Lidl',
                price: 1.99,
                updatedAt: DateTime(2026, 8, 1),
                source: MarketPriceSource.receipt,
              ),
            ],
            offers: const [],
            enabledStoreNames: const ['Lidl'],
            now: DateTime(2026, 10, 13),
            onOpenRoute: () => openedRoute = true,
          ),
        ),
      ),
    );

    expect(find.text('Preisabdeckung deiner Liste'), findsOneWidget);
    expect(find.text('Aktuell 1'), findsOneWidget);
    expect(find.text('Historisch 1'), findsOneWidget);
    expect(find.text('Unbekannt 1'), findsOneWidget);
    expect(find.text('Bekannter Warenwert'), findsOneWidget);
    expect(find.text('2,50 €'), findsOneWidget);
    expect(
      find.textContaining('Historische Werte sind nur Orientierung'),
      findsOneWidget,
    );

    await tester.tap(find.text('Preisabdeckung in der Route prüfen'));
    expect(openedRoute, isTrue);
  });

  testWidgets('zeigt bei leerer Liste einen verständlichen Einstieg', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShoppingListCostSummaryCard(
            items: [],
            marketPrices: [],
            offers: [],
          ),
        ),
      ),
    );

    expect(find.text('Preisabdeckung deiner Liste'), findsOneWidget);
    expect(
      find.text('Füge Artikel hinzu, um aktuelle Preise zu vergleichen.'),
      findsOneWidget,
    );
  });
}
