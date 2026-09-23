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

  test('parses reviewed receipt lines and keeps unknown lines for review', () {
    final result = parseReceiptLines(
      text: 'Milch 3,5%;1,29\nNicht im Katalog;4,00\nkaputte Zeile',
      storeName: 'Lidl',
      products: products,
      now: DateTime(2026, 9, 23),
    );

    expect(result.prices, hasLength(1));
    expect(result.prices.single.productId, 'milk');
    expect(result.prices.single.price, 1.29);
    expect(result.prices.single.storeName, 'Lidl');
    expect(result.unmatchedLines, contains('Nicht im Katalog;4,00'));
    expect(result.unmatchedLines, contains('kaputte Zeile'));
  });
}
