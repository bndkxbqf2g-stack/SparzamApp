import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_catalog_screen.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/models/price_sync_result.dart';

void main() {
  Widget catalog(Future<PriceSyncResult> Function({
    void Function(int, int)? onProgress,
    bool Function()? shouldCancel,
  }) onSync) => MaterialApp(
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
    await tester.pumpWidget(catalog(({onProgress, shouldCancel}) async =>
        const PriceSyncResult(
          prices: <MarketPrice>[],
          history: [],
          productsChecked: 4,
          productsWithEan: 2,
          pricesFound: 1,
          productsProcessed: 2,
          cancelled: false,
        )));
    await tester.tap(find.text('Open Prices aktualisieren'));
    await tester.pumpAndSettle();

    expect(find.text('2/2 EAN-Produkte geprüft · 1 Preis gefunden.'),
        findsOneWidget);
  });

  testWidgets('zeigt Verbindungsfehler und ermöglicht neuen Versuch',
      (tester) async {
    await tester.pumpWidget(catalog(
        ({onProgress, shouldCancel}) async => throw Exception('offline')));
    await tester.tap(find.text('Open Prices aktualisieren'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bitte Verbindung prüfen'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNotNull);
  });

  testWidgets('Teilfehler erscheint neben den gefundenen Preisen',
      (tester) async {
    await tester.pumpWidget(catalog(({
      onProgress,
      shouldCancel,
    }) async => const PriceSyncResult(
          prices: [],
          history: [],
          productsChecked: 2,
          productsWithEan: 2,
          productsProcessed: 2,
          pricesFound: 1,
          cancelled: false,
          failedProductIds: ['bad'],
        )));
    await tester.tap(find.text('Open Prices aktualisieren'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 Abfrage fehlgeschlagen'), findsOneWidget);
    expect(find.textContaining('1 Preis gefunden'), findsOneWidget);
  });

  testWidgets('Abbrechen signalisiert den laufenden Abruf', (tester) async {
    final pending = Completer<PriceSyncResult>();
    bool Function()? cancellationCheck;
    await tester.pumpWidget(catalog(({
      onProgress,
      shouldCancel,
    }) {
      cancellationCheck = shouldCancel;
      return pending.future;
    }));
    await tester.tap(find.text('Open Prices aktualisieren'));
    await tester.pump();
    expect(find.textContaining('EANs geprüft'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pump();
    expect(cancellationCheck?.call(), isTrue);
    pending.complete(const PriceSyncResult(
      prices: [],
      history: [],
      productsChecked: 2,
      productsWithEan: 2,
      pricesFound: 0,
      productsProcessed: 0,
      cancelled: true,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Abgebrochen:'), findsOneWidget);
  });
}
