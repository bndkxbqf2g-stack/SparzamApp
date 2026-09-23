import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget_plan.dart';

class BudgetStore {
  static const _monthlyKey = 'budget_monthly';
  static const _foodKey = 'budget_food';
  static const _spentKey = 'budget_food_spent';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  double _safe(double? value) =>
      value != null && value.isFinite && value >= 0 ? value : 0;

  Future<BudgetPlan> load() async => BudgetPlan(
        monthlyBudget: _safe(await _preferences.getDouble(_monthlyKey)),
        foodBudget: _safe(await _preferences.getDouble(_foodKey)),
        foodSpent: _safe(await _preferences.getDouble(_spentKey)),
      );

  Future<void> save(BudgetPlan plan) async {
    if (![plan.monthlyBudget, plan.foodBudget, plan.foodSpent]
        .every((value) => value.isFinite && value >= 0)) {
      throw ArgumentError('Budgetbeträge müssen endlich und nichtnegativ sein.');
    }
    await Future.wait([
      _preferences.setDouble(_monthlyKey, plan.monthlyBudget, null),
      _preferences.setDouble(_foodKey, plan.foodBudget, null),
      _preferences.setDouble(_spentKey, plan.foodSpent, null),
    ]);
  }
}
