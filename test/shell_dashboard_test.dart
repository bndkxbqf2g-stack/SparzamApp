import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_dashboard.dart';
import 'package:sparzamapp/features/shell/shell_routing.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/market_price.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('leerer Ausgangszustand liefert neutrales Dashboard', () {
    const mobility = MobilitySettings();
    final routing = ShellRouting(
      items: [],
      offers: [],
      mobility: mobility,
      marketPrices: [],
      roadDistances: {},
      roadMatrix: null,
    );

    final data = buildShellDashboard(
      shoppingList: const [],
      offers: const [],
      mobility: mobility,
      roadDistances: const {},
      roadMatrix: null,
      routing: routing,
      budget: const BudgetPlan(),
      purchaseHistory: const [],
      replenishment: const [],
      now: DateTime(2026, 9, 22),
    );

    expect(data.itemCount, 0);
    expect(data.routeNames, 'Noch keine Route');
    expect(data.todaySavings, 0);
    expect(data.activeOffers, 0);
  });

  test('Dashboard zählt Angebote erst ab validFrom als aktuell', () {
    const mobility = MobilitySettings();
    final routing = ShellRouting(
      items: [],
      offers: [],
      mobility: mobility,
      marketPrices: [],
      roadDistances: {},
      roadMatrix: null,
    );

    final data = buildShellDashboard(
      shoppingList: const [],
      offers: [
        Offer(
          id: 'today',
          productId: 'milk-15',
          storeName: 'ALDI Süd',
          originalPrice: 1.49,
          offerPrice: 0.95,
          validFrom: DateTime(2026, 9, 21),
          validUntil: DateTime(2026, 9, 28),
        ),
        Offer(
          id: 'future',
          productId: 'milk-35',
          storeName: 'Lidl',
          originalPrice: 1.49,
          offerPrice: 0.99,
          validFrom: DateTime(2026, 9, 23),
          validUntil: DateTime(2026, 9, 30),
        ),
        Offer(
          id: 'expired',
          productId: 'milk-35',
          storeName: 'EDEKA',
          originalPrice: 1.49,
          offerPrice: 1.09,
          validUntil: DateTime(2026, 9, 20),
        ),
      ],
      mobility: mobility,
      roadDistances: const {},
      roadMatrix: null,
      routing: routing,
      budget: const BudgetPlan(),
      purchaseHistory: const [],
      replenishment: const [],
      now: DateTime(2026, 9, 22),
    );

    expect(data.activeOffers, 1);
  });

  test('Teilroute verändert weder Sparpotenzial noch Budgetplanung', () {
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
    const mobility = MobilitySettings();
    final routing = ShellRouting(
      items: [
        ListItem(product: milk),
        ListItem(product: unknown),
      ],
      offers: [],
      mobility: mobility,
      marketPrices: [
        MarketPrice(
          productId: 'milch_35',
          storeName: 'Lidl',
          price: 1.09,
          updatedAt: DateTime(2026, 10, 1),
        ),
      ],
      roadDistances: {},
      roadMatrix: null,
    );

    final data = buildShellDashboard(
      shoppingList: routing.items,
      offers: const [],
      mobility: mobility,
      roadDistances: const {},
      roadMatrix: null,
      routing: routing,
      budget: const BudgetPlan(foodBudget: 50),
      purchaseHistory: const [],
      replenishment: const [],
      now: DateTime(2026, 10, 1),
    );

    expect(data.routeHasDataGaps, isTrue);
    expect(data.routeCoverageLabel, '1 von 2 Artikeln preislich belegt');
    expect(data.savingsHasDataGaps, isTrue);
    expect(data.todaySavings, 0);
    expect(data.budgetRemaining, 50);
  });
}
