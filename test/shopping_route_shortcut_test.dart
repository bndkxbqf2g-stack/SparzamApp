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

  testWidgets('gefüllte Einkaufsliste öffnet direkt die Sparroute', (
    tester,
  ) async {
    const product = Product(
      id: 'route_milk',
      name: 'Milch 1,5 %',
      unit: '1 l',
      group: 'milch',
    );
    var opened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingListScreen(
            items: [ListItem(product: product)],
            onAdd: (_) {},
            onChangeQuantity: (_, _) {},
            preferredProductByGroup: const {},
            recentPurchases: const [],
            onPurchased: (_, _) async {},
            onClearPurchased: (_) {},
            shoppingListStore: ShoppingListStore(),
            onOpenScanner: () {},
            onOpenRoute: () => opened++,
            offers: const [],
            priceHistory: const [],
            mobility: const MobilitySettings(),
            catalogProducts: const [product],
            marketPrices: const [],
            replenishmentSuggestions: const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shortcut = find.text('Sparroute prüfen');
    expect(shortcut, findsOneWidget);
    await tester.tap(shortcut);
    expect(opened, 1);
  });
}
