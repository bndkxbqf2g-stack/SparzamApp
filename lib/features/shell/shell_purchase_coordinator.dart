import '../../models/budget_plan.dart';
import '../../models/list_item.dart';
import '../../models/purchase_record.dart';
import '../../models/route_plan.dart';
import '../../services/budget_store.dart';
import '../../services/purchase_store.dart';
import '../../services/shopping_list_store.dart';
import '../receipt/purchase_budget_adjustment.dart';

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

  Future<PurchaseMutationResult> update({
    required PurchaseRecord record,
    required List<PurchaseRecord> history,
    required BudgetPlan budget,
    DateTime? now,
  }) async {
    final previousIndex =
        history.indexWhere((item) => item.id == record.id);
    final previous = previousIndex < 0 ? null : history[previousIndex];
    final nextHistory = await purchaseStore.add(record, history);
    if (previous == null) {
      return PurchaseMutationResult(history: nextHistory, budget: budget);
    }

    final nextBudget = budget.copyWith(
      foodSpent: adjustedFoodSpent(
        currentFoodSpent: budget.foodSpent,
        previous: previous,
        replacement: record,
        now: now,
      ),
    );
    await budgetStore.save(nextBudget);
    return PurchaseMutationResult(
      history: nextHistory,
      budget: nextBudget,
    );
  }

  Future<PurchaseMutationResult> delete({
    required PurchaseRecord record,
    required List<PurchaseRecord> history,
    required BudgetPlan budget,
    DateTime? now,
  }) async {
    final nextHistory = await purchaseStore.remove(record.id, history);
    final nextBudget = budget.copyWith(
      foodSpent: adjustedFoodSpent(
        currentFoodSpent: budget.foodSpent,
        previous: record,
        now: now,
      ),
    );
    await budgetStore.save(nextBudget);
    return PurchaseMutationResult(
      history: nextHistory,
      budget: nextBudget,
    );
  }
}
