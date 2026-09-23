import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/budget/budget_screen.dart';
import 'package:sparzamapp/models/budget_plan.dart';
import 'package:sparzamapp/services/budget_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  testWidgets('ungültiger Budgetbetrag wird nicht gespeichert', (tester) async {
    BudgetPlan? saved;
    await tester.pumpWidget(MaterialApp(
      home: BudgetScreen(
        initialPlan: const BudgetPlan(),
        store: BudgetStore(),
        plannedShop: 0,
        onChanged: (plan) => saved = plan,
      ),
    ));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lebensmittelbudget'),
      'NaN',
    );
    await tester.tap(find.text('Budget speichern'));
    await tester.pump();

    expect(saved, isNull);
    expect(find.text('Bitte einen gültigen Betrag ab 0 € eingeben'),
        findsNWidgets(3));
  });

  testWidgets('gültige Budgets werden gespeichert', (tester) async {
    BudgetPlan? saved;
    await tester.pumpWidget(MaterialApp(
      home: BudgetScreen(
        initialPlan: const BudgetPlan(),
        store: BudgetStore(),
        plannedShop: 0,
        onChanged: (plan) => saved = plan,
      ),
    ));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lebensmittelbudget'),
      '300,50',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Verfügbares Monatsbudget'),
      '500',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Diesen Monat bereits ausgegeben'),
      '50',
    );
    await tester.scrollUntilVisible(
      find.text('Budget speichern'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Budget speichern'));
    await tester.pumpAndSettle();

    expect(saved?.foodBudget, 300.50);
  });
}
