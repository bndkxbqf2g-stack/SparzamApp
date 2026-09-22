import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget_plan.dart';

class BudgetStore {
  static const _monthlyKey = 'budget_monthly';
  static const _foodKey = 'budget_food';
  static const _spentKey = 'budget_food_spent';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<BudgetPlan> load() async => BudgetPlan(
        monthlyBudget: await _preferences.getDouble(_monthlyKey) ?? 0,
        foodBudget: await _preferences.getDouble(_foodKey) ?? 0,
        foodSpent: await _preferences.getDouble(_spentKey) ?? 0,
      );

  Future<void> save(BudgetPlan plan) async {
    await Future.wait([
      _preferences.setDouble(_monthlyKey, plan.monthlyBudget),
      _preferences.setDouble(_foodKey, plan.foodBudget),
      _preferences.setDouble(_spentKey, plan.foodSpent),
    ]);
  }
}
