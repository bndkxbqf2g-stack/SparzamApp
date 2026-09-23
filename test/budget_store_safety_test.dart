import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/services/budget_store.dart';

void main() {
  test('Speichern lehnt ungültige Zahlen ab', () async {
    expect(
      () => BudgetStore().save(
        const BudgetPlan(foodBudget: double.nan),
      ),
      throwsArgumentError,
    );
  });
}
