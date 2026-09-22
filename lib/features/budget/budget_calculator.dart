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

enum BudgetForecastStatus { onTrack, warning, overBudget }

class BudgetForecast {
  const BudgetForecast({
    required this.isConfigured,
    required this.projectedFoodSpend,
    required this.projectedRemaining,
    required this.weeklyAllowance,
    required this.dailyPace,
    required this.daysRemaining,
    required this.status,
  });

  final bool isConfigured;
  final double projectedFoodSpend;
  final double projectedRemaining;
  final double weeklyAllowance;
  final double dailyPace;
  final int daysRemaining;
  final BudgetForecastStatus status;

}

BudgetSnapshot calculateBudget(BudgetPlan plan, double plannedShop) {
  final remaining = plan.foodBudget - plan.foodSpent;
  return BudgetSnapshot(
    foodRemaining: remaining,
    afterPlannedShop: remaining - plannedShop,
  );
}

BudgetForecast calculateBudgetForecast(
  BudgetPlan plan,
  double plannedShop, {
  DateTime? now,
}) {
  final date = now ?? DateTime.now();
  final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
  final elapsedDays = date.day.clamp(1, daysInMonth);
  final daysRemaining = (daysInMonth - date.day).clamp(0, daysInMonth);

  if (plan.foodBudget <= 0) {
    return BudgetForecast(
      isConfigured: false,
      projectedFoodSpend: 0,
      projectedRemaining: 0,
      weeklyAllowance: 0,
      dailyPace: 0,
      daysRemaining: daysRemaining,
      status: BudgetForecastStatus.onTrack,
    );
  }

  final spentAfterPlan = (plan.foodSpent + plannedShop)
      .clamp(0.0, double.infinity)
      .toDouble();
  final dailyPace = spentAfterPlan / elapsedDays;
  final projectedFoodSpend = dailyPace * daysInMonth;
  final projectedRemaining = plan.foodBudget - projectedFoodSpend;
  final remainingAfterPlan =
      (plan.foodBudget - spentAfterPlan).clamp(0.0, double.infinity).toDouble();
  final weeklyAllowance = daysRemaining == 0
      ? 0.0
      : remainingAfterPlan / daysRemaining * 7;

  final ratio = projectedFoodSpend / plan.foodBudget;
  final status = ratio > 1
      ? BudgetForecastStatus.overBudget
      : ratio >= 0.9
          ? BudgetForecastStatus.warning
          : BudgetForecastStatus.onTrack;

  return BudgetForecast(
    isConfigured: true,
    projectedFoodSpend: projectedFoodSpend,
    projectedRemaining: projectedRemaining,
    weeklyAllowance: weeklyAllowance,
    dailyPace: dailyPace,
    daysRemaining: daysRemaining,
    status: status,
  );
}
