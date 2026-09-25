import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/features/receipt/receipt_observation_builder.dart';
import 'package:sparzamapp/features/receipt/receipt_price_review.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('keeps unmatched receipt items as observations', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Hackfleisch gem. 4,79 B
Kartoffeln 5kg 3,99 B
Summe 8,78
Datum 23.07.26
''');
    final review = reviewReceiptPrices(draft, const <Product>[]);
    final observations =
        buildReceiptObservations(draft: draft, review: review);

    expect(observations, hasLength(2));
    expect(observations.first.familyKey, 'hackfleisch');
    expect(observations.first.productId, isNull);
    expect(observations.last.familyKey, 'kartoffeln');
  });

  test('deposits and discounts never become product observations', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Fischstäbchen 2,99 B
K Card XTRA Rabatt -0,30
Pfandartikel 0,25 A
Summe 2,94
Datum 23.07.26
''');
    final review = reviewReceiptPrices(draft, const <Product>[]);
    final observations =
        buildReceiptObservations(draft: draft, review: review);

    expect(observations, hasLength(1));
    expect(observations.single.familyKey, 'fischstäbchen');
    expect(observations.single.discounted, isTrue);
  });

  test('generic manual assignment is stored on the observation', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Hackfl. gem. 4,79 B
Summe 4,79
Datum 23.07.26
''');
    final review = reviewReceiptPrices(draft, const <Product>[]);
    final item = draft.rows.firstWhere((row) => row.kind == ReceiptRowKind.item);
    final observations = buildReceiptObservations(
      draft: draft,
      review: review,
      assignedProductIds: {item.line: 'hackfleisch'},
      confirmedProductLines: {item.line},
    );

    expect(observations.single.productId, 'hackfleisch');
    expect(observations.single.familyKey, 'hackfleisch');
    expect(observations.single.identityConfirmed, isTrue);
  });

  test('automatic catalog assignment is not treated as confirmed identity', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Unbekannte Spezialität 2,49 B
Summe 2,49
Datum 23.07.26
''');
    final review = reviewReceiptPrices(draft, const <Product>[]);
    final item =
        draft.rows.firstWhere((row) => row.kind == ReceiptRowKind.item);
    final observations = buildReceiptObservations(
      draft: draft,
      review: review,
      assignedProductIds: {item.line: 'receipt_auto_specialitaet'},
    );

    expect(observations.single.productId, 'receipt_auto_specialitaet');
    expect(observations.single.identityConfirmed, isFalse);
  });
}