import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/shell/shell_purchase_coordinator.dart';
import 'package:sparzamapp/features/shell/shell_routing.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/budget_store.dart';
import 'package:sparzamapp/services/purchase_store.dart';
import 'package:sparzamapp/services/shopping_list_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('Route abschließen speichert Menge, belastet Warenkorb und leert Liste',
      () async {
    const milk = Product(
      id: 'milch_35',
      name: 'Milch',
      unit: '1 l',
      group: 'Milch',
    );
    final items = [ListItem(product: milk, quantity: 2)];
    final listStore = ShoppingListStore();
    await listStore.save(items);
    final routing = ShellRouting(
      items: await listStore.load(),
      offers: const [],
      mobility: const MobilitySettings(
        mode: MobilityMode.bike,
        enabledStoreNames: ['Lidl'],
      ),
      marketPrices: const [],
      roadDistances: const {},
      roadMatrix: null,
    );
    final plan = routing.current!.bestPlan()!;
    final coordinator = ShellPurchaseCoordinator(
      budgetStore: BudgetStore(),
      purchaseStore: PurchaseStore(),
      shoppingListStore: listStore,
    );

    final result = await coordinator.complete(
      plan: plan,
      baselineTotal: routing.regular!.bestSingleStorePlan()!.total,
      items: items,
      history: const [],
      budget: const BudgetPlan(foodBudget: 100, foodSpent: 10),
    );

    expect(plan.basket, closeTo(2.58, 0.001));
    expect(result.history.single.items.single.quantity, 2);
    expect((await PurchaseStore().load()).single.id, result.history.single.id);
    expect((await BudgetStore().load()).foodSpent, closeTo(12.58, 0.001));
    expect(await listStore.load(), isEmpty);
  });
}
