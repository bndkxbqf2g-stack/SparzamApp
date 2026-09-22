import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/purchase_summary.dart';
import 'package:sparzamapp/models/purchase_record.dart';

void main() {
  PurchaseRecord record(DateTime date, double basket, double total, double baseline) =>
      PurchaseRecord(
        id: date.toIso8601String(),
        createdAt: date,
        storeNames: const ['Markt'],
        items: const [PurchaseLine(productId: 'x', name: 'Test', quantity: 2)],
        basket: basket,
        travel: total - basket,
        total: total,
        baselineTotal: baseline,
      );

  test('Monatsausgaben und echte Ersparnis werden nur für aktuellen Monat summiert', () {
    final result = summarizeMonth(
      [
        record(DateTime(2026, 9, 2), 40, 42, 50),
        record(DateTime(2026, 9, 18), 25, 27, 30),
        record(DateTime(2026, 8, 31), 100, 102, 120),
      ],
      now: DateTime(2026, 9, 22),
    );

    expect(result.spent, 65);
    expect(result.savings, 11);
    expect(result.purchases, 2);
  });
}
