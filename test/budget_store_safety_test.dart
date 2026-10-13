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

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('Speichern lehnt ungültige Zahlen ab', () async {
    await expectLater(
      BudgetStore().save(const BudgetPlan(foodBudget: double.nan)),
      throwsArgumentError,
    );
  });

  test('ein paralleler Read wartet auf einen laufenden Budget-Write', () async {
    final store = BudgetStore();
    final reader = BudgetStore();
    final writing = store.save(
      const BudgetPlan(monthlyBudget: 500, foodBudget: 300, foodSpent: 42),
    );
    final reading = reader.load();

    await writing;
    expect((await reading).foodSpent, 42);
    expect((await reading).foodBudget, 300);
  });
}
