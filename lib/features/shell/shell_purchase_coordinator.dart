import '../../models/budget_plan.dart';
import '../../models/list_item.dart';
import '../../models/purchase_record.dart';
import '../../models/route_plan.dart';
import '../../services/budget_store.dart';
import '../../services/purchase_store.dart';
import '../../services/shopping_list_store.dart';

class PurchaseMutationResult {
  const PurchaseMutationResult({
    required this.history,
    required this.budget,
  });

  final List<PurchaseRecord> history;
  final BudgetPlan budget;
}

class ShellPurchaseCoordinator {
  const ShellPurchaseCoordinator({
    required this.budgetStore,
    required this.purchaseStore,
    required this.shoppingListStore,
  });

  final BudgetStore budgetStore;
  final PurchaseStore purchaseStore;
  final ShoppingListStore shoppingListStore;

  Future<PurchaseMutationResult> complete({
    required RoutePlan plan,
    required double baselineTotal,
    required List<ListItem> items,
    required List<PurchaseRecord> history,
    required BudgetPlan budget,
  }) async {
    final record = PurchaseRecord.fromPlan(
      plan: plan,
      baselineTotal: baselineTotal,
      items: items,
    );
    final nextHistory = await purchaseStore.add(record, history);
    final nextBudget = budget.copyWith(
      foodSpent: budget.foodSpent + plan.basket,
    );
    await budgetStore.save(nextBudget);
    await shoppingListStore.clear();
    return PurchaseMutationResult(
      history: nextHistory,
      budget: nextBudget,
    );
  }
}
