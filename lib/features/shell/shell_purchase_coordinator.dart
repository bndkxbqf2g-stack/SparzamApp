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
    final nextBudget = budget.copyWith(
      foodSpent: budget.foodSpent + plan.basket,
    );
    try {
      final nextHistory = await purchaseStore.add(record, history);
      await budgetStore.save(nextBudget);
      await shoppingListStore.clear();
      return PurchaseMutationResult(
        history: nextHistory,
        budget: nextBudget,
      );
    } catch (_) {
      await _restore(history: history, budget: budget, items: items);
      rethrow;
    }
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
    try {
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
    } catch (_) {
      await _restore(history: history, budget: budget);
      rethrow;
    }
  }

  Future<PurchaseMutationResult> delete({
    required PurchaseRecord record,
    required List<PurchaseRecord> history,
    required BudgetPlan budget,
    DateTime? now,
  }) async {
    final nextBudget = budget.copyWith(
      foodSpent: adjustedFoodSpent(
        currentFoodSpent: budget.foodSpent,
        previous: record,
        now: now,
      ),
    );
    try {
      final nextHistory = await purchaseStore.remove(record.id, history);
      await budgetStore.save(nextBudget);
      return PurchaseMutationResult(
        history: nextHistory,
        budget: nextBudget,
      );
    } catch (_) {
      await _restore(history: history, budget: budget);
      rethrow;
    }
  }

  Future<void> _restore({
    required List<PurchaseRecord> history,
    required BudgetPlan budget,
    List<ListItem>? items,
  }) async {
    // Jeden Speicherbereich unabhängig zurücksetzen, soweit möglich.
    try {
      await purchaseStore.save(history);
    } catch (_) {
      // Der ursprüngliche Schreibfehler bleibt für die Oberfläche erhalten.
    }
    try {
      await budgetStore.save(budget);
    } catch (_) {
      // Die weiteren Rücksetzungen trotzdem versuchen.
    }
    if (items != null) {
      try {
        await shoppingListStore.save(items);
      } catch (_) {
        // Die Oberfläche erhält weiterhin den ursprünglichen Fehler.
      }
    }
  }
}
