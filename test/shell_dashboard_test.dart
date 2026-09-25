import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/shell_dashboard.dart';
import 'package:sparzamapp/features/shell/shell_routing.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/models/mobility_settings.dart';

void main() {
  test('leerer Ausgangszustand liefert neutrales Dashboard', () {
    const mobility = MobilitySettings();
    const routing = ShellRouting(
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
}
