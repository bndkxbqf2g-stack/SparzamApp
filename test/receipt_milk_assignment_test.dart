import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/features/receipt/receipt_milk_assignment.dart';
import 'package:sparzamapp/features/receipt/receipt_price_review.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const lowFat = Product(
    id: 'milch_15', name: 'Milch 1,5 %', unit: '1 l', group: 'milch');
  const whole = Product(
    id: 'milch_35', name: 'Vollmilch 3,5 %', unit: '1 l', group: 'milch');

  test('cheaper 1.5 percent milk is assigned only by explicit selection', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
K.H-Milch 2 * 0,79 1,58 B
K.H-Milch 0,93 B
Summe 2,51
Datum 14.07.24
''');
    expect(draft.balances, isTrue);
    expect(reviewReceiptPrices(draft, [lowFat, whole]).suggestions, isEmpty);
    final rows = draft.rows.where((r) => r.kind == ReceiptRowKind.item).toList();
    final cheaper = assignedKauflandMilkPrice(
        draft: draft, row: rows.first, product: lowFat);
    final dearer = assignedKauflandMilkPrice(
        draft: draft, row: rows.last, product: whole);
    expect(cheaper?.price, 0.79);
    expect(dearer?.price, 0.93);
    expect(cheaper?.productId, 'milch_15');
    expect(dearer?.productId, 'milch_35');
  });

  test('assigned product excludes unrelated discounts', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
K.H-Milch 0,93 B
Artikelrabatt -0,10
Summe 0,83
Datum 14.07.24
''');
    expect(assignedKauflandMilkPrice(
        draft: draft, row: draft.rows.first, product: whole), isNull);
  });
}
