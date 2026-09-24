import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/features/receipt/receipt_price_review.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const products = [
    Product(id: 'weintrauben', name: 'Weintrauben',
        unit: '500 g', group: 'obst'),
    Product(id: 'milch_35', name: 'Vollmilch 3,5 %',
        unit: '1 l', group: 'milch'),
    Product(id: 'hackfleisch', name: 'Hackfleisch gemischt',
        unit: '500 g', group: 'fleisch'),
  ];

  test('two balanced Kaufland receipts keep separate dates and amounts', () {
    final july = parseReceiptLedger('''
Kaufland
Preis EUR
Trauben 500g hell 1,79 B
K.H-Milch 2 * 0,85 1,70 B
Summe 3,49
Datum 23.07.26
''');
    final may = parseReceiptLedger('''
Kaufland
Preis EUR
K.H-Milch 2 * 0,95 1,90 B
Summe 1,90
Datum 26.05.26
''');
    final julyReview = reviewReceiptPrices(july, products);
    final mayReview = reviewReceiptPrices(may, products);
    expect(july.balances, isTrue);
    expect(julyReview.suggestions, hasLength(1));
    expect(julyReview.suggestions.single.price.productId, 'weintrauben');
    expect(julyReview.suggestions.single.price.price, 1.79);
    expect(julyReview.suggestions.single.price.updatedAt, DateTime(2026, 7, 23));
    expect(may.balances, isTrue);
    expect(mayReview.suggestions, isEmpty);
  });

  test('known package and fat content allow safe quantity price', () {
    final draft = parseReceiptLedger('''
Netto
EUR
2 x 0,95
GL H-Milch 3,5% 1 L 1,90 B
Hackfleisch gemischt 500g 4,49 B
SUMME [2] 6,39
Datum 24.08.26
''');
    final matches = reviewReceiptPrices(draft, products).suggestions;
    expect(matches, hasLength(2));
    expect(matches.first.price.price, 0.95);
    expect(matches.last.price.price, 4.49);
  });

  test('discounted products and unbalanced receipts cannot be promoted', () {
    final discounted = parseReceiptLedger('''
Kaufland
Preis EUR
Trauben 500g hell 1,79 B
Artikelrabatt -0,30
Summe 1,49
Datum 23.07.26
''');
    expect(reviewReceiptPrices(discounted, products).suggestions, isEmpty);
    final broken = parseReceiptLedger('''
Kaufland
Preis EUR
Trauben 500g hell 1,79 B
Summe 1,99
Datum 23.07.26
''');
    expect(reviewReceiptPrices(broken, products).suggestions, isEmpty);
  });

  test('conflicting prices for one catalog product remain unassigned', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Trauben 500g hell 1,79 B
Trauben 500g hell 1,89 B
Summe 3,68
Datum 23.07.26
''');
    expect(reviewReceiptPrices(draft, products).suggestions, isEmpty);
  });
}
