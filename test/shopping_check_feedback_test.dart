import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shopping_list/shopping_list_screen.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  testWidgets('fehlgeschlagener Kauf hebt Haken auf und ist erneut möglich',
      (tester) async {
    const product = Product(
      id: 'test_milk',
      name: 'Testmilch',
      unit: 'Liter',
      group: 'milch',
    );
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShoppingListScreen(
          items: [ListItem(product: product)],
          onAdd: (_) {},
          onChangeQuantity: (_, _) {},
          preferredProductByGroup: const {},
          recentPurchases: const [],
          onPurchased: (_, _) {
            calls++;
            return calls == 1 ? pending.future : Future<void>.value();
          },
          onClearPurchased: (_) {},
          shoppingListStore: ShoppingListStore(),
          onOpenScanner: () {},
          offers: const [],
          priceHistory: const [],
          mobility: const MobilitySettings(),
          catalogProducts: const [product],
          marketPrices: const [],
          replenishmentSuggestions: const [],
        ),
      ),
    ));
    final tile = find.widgetWithText(ListTile, 'Testmilch');
    await tester.scrollUntilVisible(tile, 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(tile);
    await tester.pump();
    await tester.tap(tile);
    await tester.pump();
    expect(calls, 1);

    pending.completeError(StateError('storage failed'));
    await tester.pump();
    expect(find.text('Kauf konnte nicht gespeichert werden.'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Testmilch')).style?.decoration,
        isNot(TextDecoration.lineThrough));

    await tester.tap(tile);
    await tester.pump();
    expect(calls, 2);
  });
}
