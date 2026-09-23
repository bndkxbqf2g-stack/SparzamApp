import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/services/budget_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('ungültige gespeicherte Zahlen werden zu null Budget', () async {
    final preferences = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = preferences;
    await preferences.setDouble('budget_monthly', double.nan);
    await preferences.setDouble('budget_food', -5);
    await preferences.setDouble('budget_food_spent', double.infinity);

    final plan = await BudgetStore().load();
    expect(plan.monthlyBudget, 0);
    expect(plan.foodBudget, 0);
    expect(plan.foodSpent, 0);
  });

  test('Speichern lehnt ungültige Zahlen ab', () async {
    expect(
      () => BudgetStore().save(
        const BudgetPlan(foodBudget: double.nan),
      ),
      throwsArgumentError,
    );
  });
}
