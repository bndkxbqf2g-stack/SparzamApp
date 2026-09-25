import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';

void main() {
  test('reconciles a wrapped Kaufland quantity and an item discount', () {
    final draft = parseReceiptLedger('''
Preis EUR
Brot 1,49 B
K Card XTRA Rabatt -0,20
Tomaten
 2 * 0,65 1,30 B
Pfandartikel 0,25 A
Summe 2,84
Kartenzahlung 2,84
''');
    expect(draft.rows, hasLength(4));
    expect(draft.rows[1].kind, ReceiptRowKind.discount);
    expect(draft.rows[1].linkedItemLine, draft.rows[0].line);
    expect(draft.rows[2].label, 'Tomaten');
    expect(draft.rows[2].quantity, 2);
    expect(draft.rows[2].unitCents, 65);
    expect(draft.rows[3].kind, ReceiptRowKind.deposit);
    expect(draft.balances, isTrue);
  });

  test('reconciles Netto prefixed quantity and keeps basket discount separate', () {
    final draft = parseReceiptLedger('''
EUR
2 x 0,85
Milch 1,5% 1L 1,70 B
Brot 1,19 B
30% Rabatt Warenkorb -0,36
SUMME [3] 2,53
Kartenzahlung EUR 2,53
''');
    expect(draft.rows[0].unitCents, 85);
    expect(draft.rows[0].quantity, 2);
    expect(draft.rows[2].linkedItemLine, isNull);
    expect(draft.balances, isTrue);
  });

  test('flags a quantity mismatch instead of inventing a correction', () {
    final draft = parseReceiptLedger('''
Preis EUR
Milch 2 * 0,95 1,80 B
Summe 1,80
''');
    expect(draft.calculatedCents, 180);
    expect(draft.balances, isFalse);
    expect(draft.unresolvedLines, contains(2));
  });
  test('fingerprint ignores payment metadata but distinguishes receipts', () {
    const body = '''
Kaufland
Preis EUR
Brot 1,49 B
Summe 1,49
Datum:23.07.26 Zeit: 10:00 Bon:1
''';
    final first = parseReceiptLedger('$body Kartenzahlung 1,49');
    final second = parseReceiptLedger('$body Terminal-ID: 9999');
    final third = parseReceiptLedger(body.replaceFirst('1,49 B', '1,39 B'));
    expect(first.receiptDate, DateTime(2026, 7, 23));
    expect(first.retailer, 'Kaufland');
    expect(first.fingerprint, second.fingerprint);
    expect(first.fingerprint, isNot(third.fingerprint));
  });
  test('recognizes EDEKA Frischemarkt receipt and reconciles euro total', () {
    final draft = parseReceiptLedger('''
Frischemarkt Trabold
Würzburger Str. 100
97225 Zellingen
EUR
COLUMBUS HUELSEN 2,65*B
AM.SP.TABAK 6,30*B
PUEBLO CLASSIC 6,50*B
BLANCHET BL.0,25L 1,69 B
G&G STREICHFETT 1,09 A
Beleg Wurst/Schinken BED / PREPACK2,16
OETK.CREME LEGERE1,39 € x 2 2,78 A
G&G HAEHNCHENBRUST 1,49 A
G&G SCHOKOL.ALP.M. 0,99 A
Posten: 10 ----------
SUMME € 25,65
Steuerübersicht NETTO 21,55
Datum 17.01.26 10:44 Uhr
AUF WIEDERSEHEN BEI EDEKA
''');

    expect(draft.retailer, 'EDEKA');
    expect(draft.receiptDate, DateTime(2026, 1, 17));
    final cremeLegere = draft.rows.firstWhere(
      (row) => row.label == 'OETK.CREME LEGERE',
    );
    expect(cremeLegere.quantity, 2);
    expect(cremeLegere.unitCents, 139);
    expect(cremeLegere.cents, 278);
    expect(draft.totalCents, 2565);
    expect(draft.calculatedCents, 2565);
    expect(draft.unresolvedLines, isEmpty);
    expect(draft.balances, isTrue);
  });

}
