import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_import.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const products = [
    Product(
      id: 'milk',
      name: 'Milch 3,5%',
      unit: '1 l',
      group: 'milch',
      aliases: ['Vollmilch'],
    ),
  ];

  test('accepts reviewed exact unit prices and retains unknown lines', () {
    final result = parseReceiptLines(
      text: 'Milch 3,5%;1,29\nNicht im Katalog;4,00\nkaputte Zeile',
      storeName: 'Lidl',
      products: products,
      now: DateTime(2026, 9, 23),
    );
    expect(result.prices, hasLength(1));
    expect(result.prices.single.productId, 'milk');
    expect(result.prices.single.price, 1.29);
    expect(result.unmatchedLines, contains('Nicht im Katalog;4,00'));
    expect(result.unmatchedLines, contains('kaputte Zeile'));
  });

  test('does not promote raw receipt totals, deposits or discounts', () {
    final result = parseReceiptLines(
      text: 'Vollmilch 1,29 €\n'
          'Vollmilch 2 * 0,95 1,90 B\n'
          'Pfandartikel 0,25 A\n'
          'K Card XTRA Rabatt -0,20\n'
          'Summe 94,99\n'
          'Vollmilch;0,95',
      storeName: 'Kaufland',
      products: products,
      now: DateTime(2026, 9, 23),
    );
    expect(result.prices, hasLength(1));
    expect(result.prices.single.price, 0.95);
    expect(result.unmatchedLines, hasLength(5));
  });

  test('does not guess from substrings or ambiguous catalog aliases', () {
    const ambiguous = [
      ...products,
      Product(id: 'other', name: 'Another milk', unit: '1 l',
          group: 'milch', aliases: ['Vollmilch']),
    ];
    final result = parseReceiptLines(
      text: 'Vollmilch;0,95\nVollmilch Bio;1,49',
      storeName: 'Lidl',
      products: ambiguous,
    );
    expect(result.prices, isEmpty);
    expect(result.unmatchedLines, hasLength(2));
  });
}
