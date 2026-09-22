import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_catalog_screen.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/models/price_sync_result.dart';

void main() {
  Widget catalog(Future<PriceSyncResult> Function() onSync) => MaterialApp(
        home: ProductCatalogScreen(
          customProducts: const [],
          marketPrices: const [],
          onSaveProduct: (product) async => [product],
          onDeleteProduct: (_) async => [],
          onSavePrice: (price) async => [price],
          onDeletePrice: (_, _) async => [],
          priceDataSettings: const PriceDataSettings(),
          onSyncOpenPrices: onSync,
        ),
      );

  testWidgets('zeigt gefundene Preise und geprüfte EANs', (tester) async {
    await tester.pumpWidget(catalog(() async => const PriceSyncResult(
          prices: <MarketPrice>[],
          history: [],
          productsChecked: 4,
          productsWithEan: 2,
          pricesFound: 1,
        )));
    await tester.tap(find.text('Open Prices aktualisieren'));
    await tester.pumpAndSettle();

    expect(find.text('2/4 Produkte mit EAN geprüft · 1 Preis gefunden.'),
        findsOneWidget);
  });

  testWidgets('zeigt Verbindungsfehler und ermöglicht neuen Versuch',
      (tester) async {
    await tester.pumpWidget(catalog(() async => throw Exception('offline')));
    await tester.tap(find.text('Open Prices aktualisieren'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bitte Verbindung prüfen'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNotNull);
  });
}
