import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_import_dialog.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/features/receipt/receipt_price_review.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const products = [
    Product(id: 'milch_35', name: 'Milch 3,5 %', unit: '1 l', group: 'milch'),
  ];

  test('checked receipt suggestion becomes an explicit row identity', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Milch 3,5 % 1,29 B
Summe 1,29
Datum 23.09.26
''');
    final review = reviewReceiptPrices(draft, products);
    expect(review.suggestions, hasLength(1));

    final selected = selectedReceiptProductAssignments(
      draft: draft,
      review: review,
      selectedPriceKeys: {'${draft.fingerprint}|milch_35'},
    );

    expect(selected[review.suggestions.single.row.line], 'milch_35');
  });

  test('unchecked receipt suggestion does not teach an identity', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Milch 3,5 % 1,29 B
Summe 1,29
Datum 23.09.26
''');
    final review = reviewReceiptPrices(draft, products);

    expect(
      selectedReceiptProductAssignments(
        draft: draft,
        review: review,
        selectedPriceKeys: const <String>{},
      ),
      isEmpty,
    );
  });
}
