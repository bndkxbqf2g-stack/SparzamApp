import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/services/budget_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('Speichern lehnt ungültige Zahlen ab', () async {
    expect(
      () => BudgetStore().save(
        const BudgetPlan(foodBudget: double.nan),
      ),
      throwsArgumentError,
    );
  });
}
