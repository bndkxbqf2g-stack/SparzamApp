import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/budget/budget_calculator.dart';
import 'package:sparzamapp/models/budget_plan.dart';

void main() {
  test('geplanter Einkauf wird vom Lebensmittel-Restbudget abgezogen', () {
    const plan = BudgetPlan(foodBudget: 400, foodSpent: 125);
    final result = calculateBudget(plan, 55);
    expect(result.foodRemaining, 275);
    expect(result.afterPlannedShop, 220);
    expect(result.overBudget, isFalse);
  });

  test('Budgetüberschreitung wird erkannt', () {
    const plan = BudgetPlan(foodBudget: 100, foodSpent: 80);
    final result = calculateBudget(plan, 30);
    expect(result.afterPlannedShop, -10);
    expect(result.overBudget, isTrue);
  });
}
