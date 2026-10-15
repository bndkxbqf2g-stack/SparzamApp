import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shopping_list/shopping_list_screen.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  const request = Product(
    id: 'custom_milk_request',
    name: 'Milch',
    unit: 'Artikel',
    group: 'milch',
  );
  const variant = Product(
    id: 'milk_15_catalog',
    name: 'Milch 1,5 %',
    unit: '1 l',
    group: 'milch',
    packageAmount: 1,
    packageUnit: 'l',
  );
  final offer = Offer(
    id: 'prospect|milk|lidl',
    productId: variant.id,
    storeName: 'Lidl',
    originalPrice: 1.49,
    originalPriceVerified: true,
    offerPrice: 0.99,
    validFrom: DateTime(2020),
    validUntil: DateTime(2099),
    source: 'retailerWebsite',
    sourceAdapter: 'kaufda',
    proofRef: 'https://example.test/prospect/milk',
    locationId: 'lidl_zellingen',
    region: 'Zellingen',
  );

  ShoppingListScreen screen(List<Product> catalog) => ShoppingListScreen(
        items: [ListItem(product: request)],
        onAdd: (_) {},
        onChangeQuantity: (_, _) {},
        preferredProductByGroup: const {},
        recentPurchases: const [],
        onPurchased: (_, _) async {},
        onClearPurchased: (_) {},
        shoppingListStore: ShoppingListStore(),
        onOpenScanner: () {},
        offers: [offer],
        priceHistory: const [],
        mobility: const MobilitySettings(enabledStoreNames: ['Lidl']),
        catalogProducts: catalog,
        marketPrices: const [],
        replenishmentSuggestions: const [],
      );

  testWidgets(
    'invalidates the shopping quote snapshot when the catalog arrives',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: screen(const <Product>[])),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Unbekannt 1'), findsOneWidget);
      expect(find.text('Aktuell 1'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(home: screen(const [variant])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktuell 1'), findsOneWidget);
      expect(find.text('Unbekannt 1'), findsNothing);
      expect(find.text('0,99 €'), findsWidgets);
    },
  );
}
