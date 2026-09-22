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

  group('Lebensmittelbudget-Prognose', () {
    test('rechnet Ausgabetempo und Wochenbudget für den Restmonat', () {
      const plan = BudgetPlan(foodBudget: 300, foodSpent: 60);

      final forecast = calculateBudgetForecast(
        plan,
        0,
        now: DateTime(2026, 9, 10),
      );

      expect(forecast.dailyPace, 6);
      expect(forecast.projectedFoodSpend, 180);
      expect(forecast.projectedRemaining, 120);
      expect(forecast.weeklyAllowance, 84);
      expect(forecast.daysRemaining, 20);
      expect(forecast.status, BudgetForecastStatus.onTrack);
    });

    test('bezieht den geplanten Einkauf in die Prognose ein', () {
      const plan = BudgetPlan(foodBudget: 300, foodSpent: 60);

      final forecast = calculateBudgetForecast(
        plan,
        30,
        now: DateTime(2026, 9, 10),
      );

      expect(forecast.dailyPace, 9);
      expect(forecast.projectedFoodSpend, 270);
      expect(forecast.projectedRemaining, 30);
      expect(forecast.weeklyAllowance, 73.5);
      expect(forecast.status, BudgetForecastStatus.warning);
    });

    test('erkennt eine voraussichtliche Überschreitung', () {
      const plan = BudgetPlan(foodBudget: 100, foodSpent: 50);

      final forecast = calculateBudgetForecast(
        plan,
        0,
        now: DateTime(2026, 9, 10),
      );

      expect(forecast.projectedFoodSpend, 150);
      expect(forecast.projectedRemaining, -50);
      expect(forecast.status, BudgetForecastStatus.overBudget);
    });

    test('liefert ohne eingerichtetes Budget neutrale Werte', () {
      const plan = BudgetPlan();

      final forecast = calculateBudgetForecast(
        plan,
        25,
        now: DateTime(2026, 9, 30),
      );

      expect(forecast.projectedFoodSpend, 0);
      expect(forecast.projectedRemaining, 0);
      expect(forecast.weeklyAllowance, 0);
      expect(forecast.dailyPace, 0);
      expect(forecast.daysRemaining, 0);
      expect(forecast.status, BudgetForecastStatus.onTrack);
    });
  });
}
