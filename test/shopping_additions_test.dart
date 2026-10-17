import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_additions.dart';
import 'package:sparzamapp/features/shopping_list/shopping_list_updates.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/recent_purchase.dart';
import 'package:sparzamapp/models/replenishment_suggestion.dart';

void main() {
  const milk = Product(id: 'milk', name: 'Milch', unit: '1 l', group: 'milch');

  test('Nachkaufvorschlag übernimmt die gelernte Menge', () {
    final products = productsForReplenishment(
      ReplenishmentSuggestion(
        product: milk,
        purchaseCount: 3,
        averageQuantity: 2.4,
        intervalDays: 7,
        lastPurchasedAt: DateTime(2026, 9, 15),
        dueAt: DateTime(2026, 9, 22),
        daysUntilDue: 0,
        urgency: ReplenishmentUrgency.overdue,
      ),
    );

    expect(products, [milk, milk]);
  });

  test('letzter Kauf fügt mindestens ein Produkt hinzu', () {
    const purchase = RecentPurchase(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
      purchaseCount: 1,
      totalQuantity: 0,
    );

    expect(productsForRecentPurchase(purchase), hasLength(1));
  });
}


  test('aktualisiert bekannte Listeneinträge ohne Nutzerzustand zu verlieren', () {
    const oldProduct = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
      packageAmount: 1,
      packageUnit: 'l',
    );
    const refreshedProduct = Product(
      id: 'milk',
      name: 'Bio Milch',
      unit: '1 l',
      group: 'milch',
      aliases: ['Kuhmilch'],
      brand: 'Hofmilch',
      packageAmount: 1,
      packageUnit: 'l',
      imageUrl: 'https://cdn.example.test/milk.jpg',
    );
    final item = ListItem(
      product: oldProduct,
      quantity: 3,
      note: 'kalt',
      checked: true,
    );

    final refreshed = refreshShoppingListProducts(
      items: [item],
      catalogProducts: [refreshedProduct],
    );

    expect(refreshed, hasLength(1));
    expect(refreshed.single.product, same(refreshedProduct));
    expect(refreshed.single.quantity, 3);
    expect(refreshed.single.note, 'kalt');
    expect(refreshed.single.checked, isTrue);
  });
