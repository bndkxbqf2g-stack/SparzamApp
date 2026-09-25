import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/purchase_budget_adjustment.dart';
import 'package:sparzamapp/models/purchase_record.dart';

void main() {
  PurchaseRecord record(String id, DateTime date, double basket) =>
      PurchaseRecord(
        id: id,
        createdAt: date,
        storeNames: const ['Lidl'],
        items: const [],
        basket: basket,
        travel: 0,
        total: basket,
        baselineTotal: basket,
      );

  test('Löschen eines aktuellen Einkaufs korrigiert das Monatsbudget', () {
    final result = adjustedFoodSpent(
      currentFoodSpent: 120,
      previous: record('1', DateTime(2026, 9, 5), 40),
      now: DateTime(2026, 9, 22),
    );

    expect(result, 80);
  });

  test('Löschen eines alten Einkaufs verändert den aktuellen Monat nicht', () {
    final result = adjustedFoodSpent(
      currentFoodSpent: 120,
      previous: record('1', DateTime(2026, 8, 31), 40),
      now: DateTime(2026, 9, 22),
    );

    expect(result, 120);
  });

  test('Verschieben über Monatsgrenze passt das Budget in beide Richtungen an', () {
    final intoCurrentMonth = adjustedFoodSpent(
      currentFoodSpent: 120,
      previous: record('1', DateTime(2026, 8, 31), 40),
      replacement: record('1', DateTime(2026, 9, 1), 40),
      now: DateTime(2026, 9, 22),
    );
    final outOfCurrentMonth = adjustedFoodSpent(
      currentFoodSpent: 120,
      previous: record('1', DateTime(2026, 9, 1), 40),
      replacement: record('1', DateTime(2026, 8, 31), 40),
      now: DateTime(2026, 9, 22),
    );

    expect(intoCurrentMonth, 160);
    expect(outOfCurrentMonth, 80);
  });
}
