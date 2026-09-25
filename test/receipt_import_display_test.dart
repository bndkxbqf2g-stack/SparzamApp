import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_import_display.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';

void main() {
  test('importable receipts are shown before blocked receipts', () {
    final blocked = parseReceiptLedger('''
EDEKA
EUR
Fanta 1,59 A
SUMME € 5,00
Datum 24.07.26
''');
    final importable = parseReceiptLedger('''
EDEKA
EUR
Schmand 0,89 B
SUMME € 0,89
Datum 17.01.26
''');

    final ordered = orderReceiptDraftsForDisplay([
      (name: 'blocked.pdf', draft: blocked),
      (name: 'importable.pdf', draft: importable),
    ]);

    expect(importableReceiptCount(ordered), 1);
    expect(ordered.first.name, 'importable.pdf');
    expect(ordered.first.draft.balances, isTrue);
    expect(ordered.last.name, 'blocked.pdf');
    expect(ordered.last.draft.balances, isFalse);
  });

  test('receipts with same validation state use stable filename order', () {
    final first = parseReceiptLedger('''
EDEKA
EUR
A 1,00 A
SUMME € 1,00
Datum 17.01.26
''');
    final second = parseReceiptLedger('''
EDEKA
EUR
B 2,00 A
SUMME € 2,00
Datum 18.01.26
''');

    final ordered = orderReceiptDraftsForDisplay([
      (name: 'z.pdf', draft: second),
      (name: 'a.pdf', draft: first),
    ]);

    expect(ordered.map((entry) => entry.name), ['a.pdf', 'z.pdf']);
  });
}
