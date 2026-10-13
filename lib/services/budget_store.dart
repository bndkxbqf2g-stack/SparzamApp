import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget_plan.dart';
import 'sequential_operation_queue.dart';

class BudgetStore {
  static const _monthlyKey = 'budget_monthly';
  static const _foodKey = 'budget_food';
  static const _spentKey = 'budget_food_spent';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  double _safe(double? value) =>
      value != null && value.isFinite && value >= 0 ? value : 0;

  Future<BudgetPlan> load() => _queue.schedule(_loadNow);

  Future<BudgetPlan> _loadNow() async => BudgetPlan(
        monthlyBudget: _safe(await _preferences.getDouble(_monthlyKey)),
        foodBudget: _safe(await _preferences.getDouble(_foodKey)),
        foodSpent: _safe(await _preferences.getDouble(_spentKey)),
      );

  Future<void> save(BudgetPlan plan) => _queue.schedule(() => _saveNow(plan));

  Future<void> _saveNow(BudgetPlan plan) async {
    if (![plan.monthlyBudget, plan.foodBudget, plan.foodSpent]
        .every((value) => value.isFinite && value >= 0)) {
      throw ArgumentError('Budgetbeträge müssen endlich und nichtnegativ sein.');
    }
    await Future.wait([
      _preferences.setDouble(_monthlyKey, plan.monthlyBudget),
      _preferences.setDouble(_foodKey, plan.foodBudget),
      _preferences.setDouble(_spentKey, plan.foodSpent),
    ]);
  }
}
