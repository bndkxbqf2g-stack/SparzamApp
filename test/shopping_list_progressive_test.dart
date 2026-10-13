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

  testWidgets('lädt Warengruppen im Einkaufslistenpfad schrittweise', (
    tester,
  ) async {
    const groups = <String>[
      'obst',
      'milch',
      'fleisch',
      'backwaren',
      'getraenke',
      'nudeln',
      'vorrat',
      'tiefkuehl',
      'haushalt',
    ];
    final products = List<Product>.generate(
      groups.length,
      (index) => Product(
        id: 'shopping-progress-$index',
        name: 'Produkt $index',
        unit: '1 Stück',
        group: groups[index],
      ),
    );
    final items = products
        .map((product) => ListItem(product: product))
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingListScreen(
            items: items,
            onAdd: (_) {},
            onChangeQuantity: (_, _) {},
            preferredProductByGroup: const {},
            recentPurchases: const [],
            onPurchased: (_, _) async {},
            onClearPurchased: (_) {},
            shoppingListStore: ShoppingListStore(),
            onOpenScanner: () {},
            offers: const [],
            priceHistory: const [],
            mobility: const MobilitySettings(),
            catalogProducts: products,
            marketPrices: const [],
            replenishmentSuggestions: const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    final loadMore = find.byKey(
      const ValueKey('shopping-groups-load-more'),
    );
    await tester.scrollUntilVisible(
      loadMore,
      300,
      scrollable: scrollable,
    );

    expect(
      find.byKey(const ValueKey('shopping-group-haushalt')),
      findsNothing,
    );
    expect(loadMore, findsOneWidget);
    tester.widget<OutlinedButton>(loadMore).onPressed!.call();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('shopping-group-Gruppe 8')),
      findsOneWidget,
    );
  });
}
