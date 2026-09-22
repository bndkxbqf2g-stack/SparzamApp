import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/market_price_editor_screen.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const product = Product(id: 'milk', name: 'Milch', unit: 'Stück', group: 'Milch');
  final price = MarketPrice(
    productId: product.id,
    storeName: 'Lidl',
    price: 1.99,
    updatedAt: DateTime(2026, 9, 1),
  );

  testWidgets('Fehler beim Löschen behält Preis und Eingabe', (tester) async {
    final pending = Completer<List<MarketPrice>>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: MarketPriceEditorScreen(
        product: product,
        prices: [price],
        openPricesMaxAgeDays: 30,
        onSave: (_) async => [price],
        onDelete: (_, __) {
          calls++;
          return pending.future;
        },
      ),
    ));

    await tester.tap(find.byTooltip('Eigenen Preis löschen'));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('1.99'), findsOneWidget);
    await tester.tap(find.byTooltip('Eigenen Preis löschen'));
    expect(calls, 1);

    pending.completeError(StateError('save failed'));
    await tester.pump();
    expect(find.text('1.99'), findsOneWidget);
    expect(find.text('Der Preis konnte nicht gelöscht werden.'), findsOneWidget);
  });

  testWidgets('Ungültige Eingabe wird nicht gespeichert', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: MarketPriceEditorScreen(
        product: product,
        prices: const [],
        openPricesMaxAgeDays: 30,
        onSave: (_) async {
          calls++;
          return [];
        },
        onDelete: (_, __) async => [],
      ),
    ));

    await tester.enterText(find.byType(TextField).first, 'NaN');
    await tester.tap(find.byTooltip('Speichern').first);
    await tester.pump();
    expect(calls, 0);
    expect(find.text('Bitte einen gültigen Preis über 0 € eingeben.'),
        findsOneWidget);
  });
}
