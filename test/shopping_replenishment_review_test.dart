import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shopping_list/shopping_list_screen.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/replenishment_suggestion.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  testWidgets('Nachkaufvorschlag prüft aktuelle Angebote vor dem Einfügen', (
    tester,
  ) async {
    const milk = Product(
      id: 'milk-15',
      name: 'Milch 1,5 %',
      unit: '1 l',
      group: 'milch',
    );
    final suggestion = ReplenishmentSuggestion(
      product: milk,
      purchaseCount: 3,
      averageQuantity: 2,
      intervalDays: 7,
      lastPurchasedAt: DateTime(2026, 9, 8),
      dueAt: DateTime(2026, 9, 15),
      daysUntilDue: 0,
      urgency: ReplenishmentUrgency.overdue,
    );
    final added = <Product>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingListScreen(
            items: const [],
            onAdd: added.add,
            onChangeQuantity: (_, _) {},
            preferredProductByGroup: const {},
            recentPurchases: const [],
            onPurchased: (_, _) async {},
            onClearPurchased: (_) {},
            shoppingListStore: ShoppingListStore(),
            onOpenScanner: () {},
            offers: [
              Offer(
                id: 'milk-offer',
                productId: milk.id,
                storeName: 'ALDI Süd',
                originalPrice: 1.29,
                offerPrice: 0.95,
                validUntil: DateTime(2099, 1, 1),
              ),
            ],
            priceHistory: const [],
            mobility: const MobilitySettings(),
            catalogProducts: const [milk],
            marketPrices: const [],
            replenishmentSuggestions: [suggestion],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Angebote und Varianten prüfen'));
    await tester.pumpAndSettle();
    expect(find.text('Milch 1,5 % · Empfehlung'), findsOneWidget);
    await tester.tap(find.text('1 Artikel übernehmen'));
    await tester.pumpAndSettle();

    expect(added, [milk, milk]);
  });
}
