import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';

void main() {
  test('real Lidl Plus receipt 07.05.2026 balances with discounts and weight', () {
    final draft = parseReceiptLedger('''
LIDL
Am Güßgraben 2
97225 Zellingen
EUR
Banane lose 0,53 A
0,414 kg x 1,29 EUR/kg
Lidl Plus Rabatt -0,01
Trauben hell kernlos 1,89 A
Lidl Plus Rabatt -0,11
Apfel rot 1,69 A
Lidl Plus Rabatt -0,09
Zitronen 1,49 A
Lidl Plus Rabatt -0,08
Wagner Backfr.Mozza. 3,69 x 2 7,38 A
Lidl Plus Rabatt -0,42
Kartoffeltas.Spinat 2,19 A
Lidl Plus Rabatt -0,22
Lidl Plus Rabatt -0,11
Laugenbrezel 10er 1,99 A
Lidl Plus Rabatt -0,20
Lidl Plus Rabatt -0,10
Käseaufschnitt light 1,89 A
Lidl Plus Rabatt -0,11
Salakis Light 1,99 A
Lidl Plus Rabatt -0,20
Lidl Plus Rabatt -0,10
Pfeffer-Schinkenbr. 1,69 A
Preisvorteil -0,10
Lidl Plus Rabatt -0,09
Hähnchenbrustf.Curry 1,59 A
Lidl Plus Rabatt -0,09
Edelsalami geschnit. 1,49 A
Lidl Plus Rabatt -0,08
Körniger Frischkäse 1,19 A
Lidl Plus Rabatt -0,07
Frischkäse Balance 1,19 A
Preisvorteil -0,20
Lidl Plus Rabatt -0,06
Camembert 30% 1,09 A
Preisvorteil -0,10
Lidl Plus Rabatt -0,06
Bärenm.H-Milch 3,5% 0,95 x 2 1,90 A
Lidl Plus Rabatt -0,10
Schmelzkäse Burger 1,99 A
Preisvorteil -0,20
Lidl Plus Rabatt -0,10
H-Milch 0,1% 0,75 x 2 1,50 A
Lidl Plus Rabatt -0,08
Granini Nekt. Multi 1,69 B
Lidl Plus Rabatt -0,09
Pfand 0,25 M 0,25 B
Toastbrötchen Mehrk. 0,99 A
Lidl Plus Rabatt -0,15
Lidl Plus Rabatt -0,05
zu zahlen 34,23
Kreditkarte 34,23
07.05.26 18:10
''');

    expect(draft.retailer, 'Lidl');
    expect(draft.receiptDate, DateTime(2026, 5, 7));
    expect(draft.totalCents, 3423);
    expect(draft.calculatedCents, 3423);
    expect(draft.unresolvedLines, isEmpty);
    expect(draft.balances, isTrue);

    final bananas = draft.rows.firstWhere((row) => row.label == 'Banane lose');
    expect(bananas.quantity, closeTo(0.414, 0.000001));
    expect(bananas.quantityUnit, 'kg');
    expect(bananas.unitCents, 129);

    final pizza =
        draft.rows.firstWhere((row) => row.label == 'Wagner Backfr.Mozza.');
    expect(pizza.quantity, 2);
    expect(pizza.unitCents, 369);

    expect(
      draft.rows.where((row) => row.kind == ReceiptRowKind.discount),
      isNotEmpty,
    );
    expect(
      draft.rows.where((row) => row.kind == ReceiptRowKind.deposit),
      hasLength(1),
    );
  });

  test('real Lidl Plus receipt 18.07.2026 balances multi-buy and deposits', () {
    final draft = parseReceiptLedger('''
LIDL
Am Güßgraben 2
97225 Zellingen
EUR
Apfel rot süß 1,99 A
Lidl Plus Rabatt -0,13
Suppengrün 1,99 A
Preisvorteil -0,20
Lidl Plus Rabatt -0,11
Broccoli 2,39 A
Lidl Plus Rabatt -0,36
Lidl Plus Rabatt -0,13
Katenschinken gewürf 2,39 A
Preisvorteil -0,10
Lidl Plus Rabatt -0,40
Lidl Plus Rabatt -0,13
4-Käse-Mischung 1,79 x 2 3,58 A
Lidl Plus Rabatt -0,22
8 Delikatess Wiener 2,99 A
Lidl Plus Rabatt -0,19
Crème Fraiche Natur 0,99 x 3 2,97 A
Lidl Plus Rabatt -0,18
Creme z. Kochen 7% 0,89 x 2 1,78 A
Lidl Plus Rabatt -0,12
Körniger Frischkäse 1,19 A
Lidl Plus Rabatt -0,08
Södergarden unges. 1,05 A
Lidl Plus Rabatt -0,07
Joghurt mild 1,5% 0,79 A
Lidl Plus Rabatt -0,05
Fr.Eier.a. Bodenhal. 2,49 A
Lidl Plus Rabatt -0,16
Getr. Tomaten in Öl 1,99 A
Lidl Plus Rabatt -0,13
Bio Mandeldrink 1,35 B
Lidl Plus Rabatt -0,20
Lidl Plus Rabatt -0,07
Die Feine Erdb.-Joh. 1,29 A
Lidl Plus Rabatt -0,13
Lidl Plus Rabatt -0,07
H-Milch 3,5% 0,95 A
Lidl Plus Rabatt -0,06
H-Milch 1,5% 0,85 A
Lidl Plus Rabatt -0,05
Senf mittelscharf 0,69 A
Lidl Plus Rabatt -0,04
Passata di pomodoro 1,39 A
Lidl Plus Rabatt -0,09
Gehackte Tomaten 0,59 x 2 1,18 A
Lidl Plus Rabatt -0,08
Passierte Tomaten 0,65 x 2 1,30 A
Lidl Plus Rabatt -0,08
Weißburgund. trocken 1,99 B
Lidl Plus Rabatt -0,13
Löwenbräu Original 0,99 x 2 1,98 B
Lidl Plus Rabatt -0,12
Pfand 0,25 M 0,25 x 2 0,50 B
Veltins PilsenerDose 0,99 B
Lidl Plus Rabatt -0,06
Pfand 0,25 M 0,25 B
Vollkorn Toast 0,89 A
Lidl Plus Rabatt -0,06
Geschirrs.AloeVera 0,75 B
Lidl Plus Rabatt -0,05
QS Rinderhack 18% 5,29 A
Lidl Plus Rabatt -0,34
zu zahlen 44,84
Kreditkarte 44,84
18.07.26 16:29
''');

    expect(draft.retailer, 'Lidl');
    expect(draft.receiptDate, DateTime(2026, 7, 18));
    expect(draft.totalCents, 4484);
    expect(draft.calculatedCents, 4484);
    expect(draft.unresolvedLines, isEmpty);
    expect(draft.balances, isTrue);

    final creme =
        draft.rows.firstWhere((row) => row.label == 'Crème Fraiche Natur');
    expect(creme.quantity, 3);
    expect(creme.unitCents, 99);

    final deposit = draft.rows.firstWhere(
      (row) => row.kind == ReceiptRowKind.deposit && row.quantity == 2,
    );
    expect(deposit.cents, 50);
    expect(deposit.unitCents, 25);
  });
}
