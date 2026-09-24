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
}
