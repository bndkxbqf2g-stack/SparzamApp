import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/features/receipt/receipt_observation_builder.dart';
import 'package:sparzamapp/features/receipt/receipt_price_review.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('real EDEKA 17.01.2026 receipt becomes nine price observations', () {
    final draft = parseReceiptLedger('''
Frischemarkt Trabold
Würzburger Str. 100
97225 Zellingen
Tel. 09364/2559
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
Mastercard € 25,65
Datum 17.01.26 10:44 Uhr
BITTE BELEG AUFBEWAHRENMwSt NETTO MwSt UMSATZ
A 7% 7,95 0,56 8,51
B 19% 14,40 2,74 17,14
AUF WIEDERSEHEN BEI EDEKA
''');

    final review = reviewReceiptPrices(draft, const <Product>[]);
    final observations =
        buildReceiptObservations(draft: draft, review: review);

    expect(draft.retailer, 'EDEKA');
    expect(draft.receiptDate, DateTime(2026, 1, 17));
    expect(draft.balances, isTrue);
    expect(draft.rows.where((row) => row.kind == ReceiptRowKind.item), hasLength(9));
    expect(observations, hasLength(9));
    expect(observations.map((entry) => entry.storeName).toSet(), {'EDEKA'});
    expect(observations.map((entry) => entry.totalPrice).toList(), [
      2.65,
      6.30,
      6.50,
      1.69,
      1.09,
      2.16,
      2.78,
      1.49,
      0.99,
    ]);

    final cremeLegere = observations.singleWhere(
      (entry) => entry.rawLabel == 'OETK.CREME LEGERE',
    );
    expect(cremeLegere.quantity, 2);
    expect(cremeLegere.unitPrice, 1.39);
  });
}
