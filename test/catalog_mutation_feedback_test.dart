import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_catalog_screen.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/models/price_sync_result.dart';

void main() {
  const product = Product(
    id: 'custom_test',
    name: 'Testprodukt',
    unit: 'Artikel',
    group: 'custom',
  );

  Widget catalog({
    required Future<List<Product>> Function(Product) onSave,
    required Future<List<Product>> Function(Product) onDelete,
  }) => MaterialApp(
        home: ProductCatalogScreen(
          customProducts: const [product],
          marketPrices: const [],
          onSaveProduct: onSave,
          onDeleteProduct: onDelete,
          onSavePrice: (_) async => [],
          onDeletePrice: (_, _) async => [],
          priceDataSettings: const PriceDataSettings(),
          onSyncOpenPrices: ({onProgress, shouldCancel, retryProductIds}) async =>
              const PriceSyncResult(
            prices: [],
            history: [],
            productsChecked: 0,
            productsWithEan: 0,
            pricesFound: 0,
            productsProcessed: 0,
            cancelled: false,
          ),
        ),
      );

  Future<void> choose(WidgetTester tester, String action) async {
    await tester.enterText(find.byType(TextField).first, 'Testprodukt');
    await tester.pump();
    await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(action).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Fehler beim Produktlöschen lässt Eintrag und Bedienung bestehen',
      (tester) async {
    final pending = Completer<List<Product>>();
    var calls = 0;
    await tester.pumpWidget(catalog(
      onSave: (_) async => [product],
      onDelete: (_) {
        calls++;
        return pending.future;
      },
    ));
    await choose(tester, 'Löschen');
    await tester.tap(find.text('Löschen').last);
    await tester.pump();
    expect(calls, 1);
    pending.completeError(StateError('storage failed'));
    await tester.pump();
    expect(find.text('Produkt konnte nicht gelöscht werden.'), findsOneWidget);
    expect(find.text('Testprodukt'), findsOneWidget);
    expect(tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>).first,
    ).enabled, isTrue);
  });

  testWidgets('Fehler beim Speichern wird gemeldet', (tester) async {
    await tester.pumpWidget(catalog(
      onSave: (_) async => throw StateError('storage failed'),
      onDelete: (_) async => [],
    ));
    await choose(tester, 'Bearbeiten');
    await tester.ensureVisible(find.text('Produkt speichern'));
    await tester.tap(find.text('Produkt speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Produkt konnte nicht gespeichert werden.'), findsOneWidget);
    expect(find.text('Testprodukt'), findsOneWidget);
  });
}
