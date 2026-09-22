import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shell/shell_purchase_coordinator.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/models/route_plan.dart';
import 'package:sparzamapp/models/purchase_record.dart';
import 'package:sparzamapp/models/store.dart';
import 'package:sparzamapp/services/budget_store.dart';
import 'package:sparzamapp/services/purchase_store.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('Einkaufsabschluss speichert Historie und belastet Budget', () async {
    final coordinator = ShellPurchaseCoordinator(
      budgetStore: BudgetStore(),
      purchaseStore: PurchaseStore(),
      shoppingListStore: ShoppingListStore(),
    );
    const store = Store(
      name: 'Lidl',
      location: 'Zellingen',
      distanceKm: 2,
      prices: {},
    );
    const plan = RoutePlan(
      stores: [store],
      assignments: {},
      basket: 40,
      travel: 1,
      total: 41,
      unassigned: [],
    );

    final result = await coordinator.complete(
      plan: plan,
      baselineTotal: 50,
      items: const [],
      history: const [],
      budget: const BudgetPlan(foodBudget: 300, foodSpent: 80),
    );

    expect(result.history, hasLength(1));
    expect(result.budget.foodSpent, 120);
    expect((await BudgetStore().load()).foodSpent, 120);
  });

  test('Korrektur und Löschen passen das aktuelle Monatsbudget an', () async {
    final coordinator = ShellPurchaseCoordinator(
      budgetStore: BudgetStore(),
      purchaseStore: PurchaseStore(),
      shoppingListStore: ShoppingListStore(),
    );
    final original = PurchaseRecord(
      id: '1',
      createdAt: DateTime(2026, 9, 5),
      storeNames: const ['Lidl'],
      items: const [],
      basket: 40,
      travel: 0,
      total: 40,
      baselineTotal: 50,
    );
    final corrected = original.copyWith(basket: 30, total: 30);

    final updated = await coordinator.update(
      record: corrected,
      history: [original],
      budget: const BudgetPlan(foodBudget: 300, foodSpent: 100),
      now: DateTime(2026, 9, 22),
    );
    final deleted = await coordinator.delete(
      record: corrected,
      history: updated.history,
      budget: updated.budget,
      now: DateTime(2026, 9, 22),
    );

    expect(updated.budget.foodSpent, 90);
    expect(deleted.budget.foodSpent, 60);
    expect(deleted.history, isEmpty);
  });
}
