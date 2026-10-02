import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/features/receipt/receipt_price_review.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const products = [
    Product(id: 'bananen', name: 'Bananen', unit: '1 kg', group: 'obst'),
    Product(
      id: 'weintrauben',
      name: 'Weintrauben',
      unit: '500 g',
      group: 'obst',
    ),
    Product(
      id: 'milch_35',
      name: 'Vollmilch 3,5 %',
      unit: '1 l',
      group: 'milch',
    ),
    Product(
      id: 'hackfleisch',
      name: 'Hackfleisch gemischt',
      unit: '500 g',
      group: 'fleisch',
    ),
  ];

  test('two balanced Kaufland receipts keep separate dates and amounts', () {
    final july = parseReceiptLedger('''
Kaufland
Preis EUR
Trauben 500g hell 1,73 B
K.H-Milch 2 * 0,85 1,70 B
Summe 3,43
Datum 23.07.24
''');
    final may = parseReceiptLedger('''
Kaufland
Preis EUR
K.H-Milch 2 * 0,95 1,90 B
Summe 1,90
Datum 26.05.24
''');
    final julyReview = reviewReceiptPrices(july, products);
    final mayReview = reviewReceiptPrices(may, products);
    expect(july.balances, isTrue);
    expect(julyReview.suggestions, hasLength(1));
    expect(julyReview.suggestions.single.price.productId, 'weintrauben');
    expect(julyReview.suggestions.single.price.price, 1.73);
    expect(
      julyReview.suggestions.single.price.updatedAt,
      DateTime(2024, 7, 23),
    );
    expect(may.balances, isTrue);
    expect(mayReview.suggestions, isEmpty);
  });

  test('known package and fat content allow safe quantity price', () {
    final draft = parseReceiptLedger('''
Netto
EUR
2 x 0,95
GL H-Milch 3,5% 1 L 1,90 B
Hackfleisch gemischt 500g 4,39 B
SUMME [2] 6,29
Datum 24.08.24
''');
    final matches = reviewReceiptPrices(draft, products).suggestions;
    expect(matches, hasLength(2));
    expect(matches.first.price.price, 0.95);
    expect(matches.last.price.price, 4.39);
  });

  test('discounted products and unbalanced receipts cannot be promoted', () {
    final discounted = parseReceiptLedger('''
Kaufland
Preis EUR
Trauben 500g hell 1,73 B
Artikelrabatt -0,30
Summe 1,43
Datum 23.07.24
''');
    expect(reviewReceiptPrices(discounted, products).suggestions, isEmpty);
    final broken = parseReceiptLedger('''
Kaufland
Preis EUR
Trauben 500g hell 1,73 B
Summe 1,93
Datum 23.07.24
''');
    expect(reviewReceiptPrices(broken, products).suggestions, isEmpty);
  });

  test('Netto kilogram price after item gives exact banana unit price', () {
    final draft = parseReceiptLedger('''
Netto
EUR
Bananen Lose MT 0,46 B
0,464 kg x 1,00 EUR/kg
SUMME [1] 0,46
Datum 14.07.24
''');
    expect(draft.balances, isTrue);
    final suggestion = reviewReceiptPrices(draft, products).suggestions.single;
    expect(suggestion.price.productId, 'bananen');
    expect(suggestion.price.price, 1);
    expect(suggestion.row.quantity, 0.464);
  });

  test('weight without a printed unit price preserves purchased mass', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Bananen kg 0,498 kg 0,64 B
Summe 0,64
Datum 14.07.24
''');
    expect(draft.balances, isTrue);
    expect(draft.rows.single.quantity, closeTo(0.498, 0.000001));
    expect(draft.rows.single.quantityUnit, 'kg');
    expect(draft.rows.single.unitCents, isNull);
    expect(reviewReceiptPrices(draft, products).suggestions, isEmpty);
  });

  test('conflicting prices for one catalog product remain unassigned', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Trauben 500g hell 1,73 B
Trauben 500g hell 1,83 B
Summe 3,56
Datum 23.07.24
''');
    expect(reviewReceiptPrices(draft, products).suggestions, isEmpty);
  });

  test(
    'unique learned receipt alias wins over compatible sibling variants',
    () {
      final draft = parseReceiptLedger('''
Kaufland
Preis EUR
K.H-Milch 2 * 0,85 1,70 B
Summe 1,70
Datum 23.07.24
''');
      final matches = reviewReceiptPrices(draft, [
        const Product(
          id: 'h-milk',
          name: 'H-Milch',
          unit: '1 l',
          group: 'milch',
          aliases: ['K.H-Milch'],
        ),
        const Product(
          id: 'milk-15',
          name: 'Milch 1,5 %',
          unit: '1 l',
          group: 'milch',
        ),
        const Product(
          id: 'milk-35',
          name: 'Vollmilch 3,5 %',
          unit: '1 l',
          group: 'milch',
        ),
      ]).suggestions;

      expect(matches, hasLength(1));
      expect(matches.single.product.id, 'h-milk');
      expect(matches.single.price.price, 0.85);
    },
  );

  test('conflicting exact aliases remain unresolved', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
K.H-Milch 0,85 B
Summe 0,85
Datum 23.07.24
''');
    final products = [
      const Product(
        id: 'milk-a',
        name: 'H-Milch A',
        unit: '1 l',
        group: 'milch',
        aliases: ['K.H-Milch'],
      ),
      const Product(
        id: 'milk-b',
        name: 'H-Milch B',
        unit: '1 l',
        group: 'milch',
        aliases: ['K.H-Milch'],
      ),
    ];

    expect(reviewReceiptPrices(draft, products).suggestions, isEmpty);
  });

  test(
    'receipt simulation separates donut, knabbermaeuse and tomato variants',
    () {
      final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Pizza-Donut Schin. 0,89 B
K.Passata Rus.Bas. 1,49 B
KLC Geh. Tomaten 2 * 0,59 1,18 B
KLC.Kn.Mäuse Salz 1,19 B
Summe 4,75
Datum 26.05.26
''');
      final matches = reviewReceiptPrices(draft, const [
        Product(
          id: 'pizza-donut',
          name: 'Pizza-Donut Schinken',
          unit: 'Packung',
          group: 'backwaren',
          aliases: ['Pizza-Donut Schin.'],
        ),
        Product(
          id: 'passata',
          name: 'Passierte Tomaten',
          unit: '500 g',
          group: 'vorrat',
        ),
        Product(
          id: 'chopped',
          name: 'Gehackte Tomaten',
          unit: '400 g',
          group: 'vorrat',
          aliases: ['dosentomaten'],
        ),
        Product(
          id: 'mice',
          name: 'Knabbermäuse Salz',
          unit: 'Packung',
          group: 'vorrat',
          aliases: ['KLC.Kn.Mäuse Salz'],
        ),
      ]);

      expect(draft.balances, isTrue);
      expect(matches.suggestions.map((entry) => entry.product.id), [
        'pizza-donut',
        'passata',
        'chopped',
        'mice',
      ]);
      expect(matches.suggestions.map((entry) => entry.price.price), [
        0.89,
        1.49,
        0.59,
        1.19,
      ]);
    },
  );
}
