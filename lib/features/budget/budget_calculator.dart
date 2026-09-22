import '../../models/budget_plan.dart';

class BudgetSnapshot {
  const BudgetSnapshot({
    required this.foodRemaining,
    required this.afterPlannedShop,
  });

  final double foodRemaining;
  final double afterPlannedShop;

  bool get overBudget => afterPlannedShop < 0;
}

BudgetSnapshot calculateBudget(BudgetPlan plan, double plannedShop) {
  final remaining = plan.foodBudget - plan.foodSpent;
  return BudgetSnapshot(
    foodRemaining: remaining,
    afterPlannedShop: remaining - plannedShop,
  );
}
