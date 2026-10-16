import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/product_catalog_screen.dart';
import 'package:sparzamapp/models/price_data_settings.dart';
import 'package:sparzamapp/models/price_sync_result.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const extraProduct = Product(
    id: 'zz_catalog_test',
    name: 'ZZZ Testprodukt',
    unit: '1 Stück',
    group: 'test',
  );

  Widget catalog() => MaterialApp(
        home: ProductCatalogScreen(
          customProducts: const [extraProduct],
          marketPrices: const [],
          onSaveProduct: (product) async => [product],
          onDeleteProduct: (_) async => const [],
          onSavePrice: (_) async => const [],
          onDeletePrice: (_, _) async => const [],
          priceDataSettings: const PriceDataSettings(
            openPricesEnabled: false,
          ),
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

  int shownProducts(WidgetTester tester) {
    final summary = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data ?? '').endsWith('Produkten angezeigt'),
      ),
    );
    return int.parse(
      RegExp(r'^(\d+) von').firstMatch(summary.data!)!.group(1)!,
    );
  }

  testWidgets('rendert den Produktkatalog seitenweise', (tester) async {
    await tester.pumpWidget(catalog());
    await tester.pump();

    final before = shownProducts(tester);
    expect(before, lessThan(100));
    expect(find.widgetWithText(ListTile, 'ZZZ Testprodukt'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -10000));
    await tester.pump();
    final more = find.textContaining('Weitere Produkte laden');
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pump();

    expect(shownProducts(tester), greaterThan(before));
  });
}
