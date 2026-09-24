import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_assigned_price.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('exact Schmand receipt identity becomes a direct Kaufland price', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
K.Frischer Schmand 0,79 B
K Card XTRA Rabatt -0,16
Summe 0,63
Datum:23.07.26 Zeit: 12:52
''');
    const product = Product(
      id: 'receipt_auto_schmand',
      name: 'K.Frischer Schmand',
      unit: 'Stück',
      group: 'schmand',
      aliases: ['K.Frischer Schmand'],
    );

    final price = assignedReceiptPrice(
      draft: draft,
      row: draft.rows.first,
      product: product,
    );

    expect(draft.balances, isTrue);
    expect(price, isNotNull);
    expect(price!.price, 0.79);
    expect(price.storeName, 'Kaufland');
  });

  test('broad family identity does not become an exact direct price', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
K.Frischer Schmand 0,79 B
Summe 0,79
Datum:23.07.26 Zeit: 12:52
''');
    const generic = Product(
      id: 'schmand',
      name: 'Schmand',
      unit: 'Stück',
      group: 'schmand',
    );

    expect(
      assignedReceiptPrice(
        draft: draft,
        row: draft.rows.first,
        product: generic,
      ),
      isNull,
    );
  });
}
