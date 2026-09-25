import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_additions.dart';
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
