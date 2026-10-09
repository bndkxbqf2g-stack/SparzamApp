import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/data/stores.dart';
import 'package:sparzamapp/features/store/store_screen.dart';
import 'package:sparzamapp/features/price_gaps/price_gap_priority.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets('Marktansicht zeigt fehlende Preise als unvollständige Abdeckung',
      (tester) async {
    const milk = Product(
      id: 'milch_35',
      name: 'Vollmilch',
      unit: '1 l',
      group: 'milch',
    );
    const unknown = Product(
      id: 'unknown',
      name: 'Unbekannter Artikel',
      unit: 'Stück',
      group: 'test',
    );
    final lidl = stores.firstWhere((store) => store.name == 'Lidl');

    await tester.pumpWidget(
      MaterialApp(
        home: StoreScreen(
          store: lidl,
          items: [
            ListItem(product: milk),
            ListItem(product: unknown),
          ],
          offers: const [],
          mobility: const MobilitySettings(),
          marketPrices: [
            MarketPrice(
              productId: milk.id,
              storeName: lidl.name,
              price: 1.09,
              updatedAt: DateTime(2026, 10, 1),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The additional priority card pushes the value summary below the initial
    // viewport; the visible warning is the stable assertion for this screen.
    expect(find.text('Preisabdeckung unvollständig'), findsOneWidget);
    expect(
      find.textContaining('1 von 2 Artikeln mit aktuellem, vergleichbarem Preis'),
      findsOneWidget,
    );
    expect(find.text('Preis-Datenlücken zuerst klären'), findsOneWidget);
    expect(find.textContaining('Menge 1 · 1 Markt ohne Preis'), findsOneWidget);
    expect(find.text('Dieser Markt lohnt sich durch die Angebote'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Marktansicht öffnet die Preiseingabe für eine Datenlücke',
      (tester) async {
    const milk = Product(
      id: 'milch_35',
      name: 'Vollmilch',
      unit: '1 l',
      group: 'milch',
    );
    final lidl = stores.firstWhere((store) => store.name == 'Lidl');
    PriceGapPriority? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: StoreScreen(
          store: lidl,
          items: [ListItem(product: milk)],
          offers: const [],
          mobility: const MobilitySettings(),
          marketPrices: const [],
          onResolvePriceGap: (gap) async => selected = gap,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preis ergänzen'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pump();
    await tester.tap(find.text('Preis ergänzen'));
    await tester.pump();

    expect(selected?.item.product.id, milk.id);
  });
}
