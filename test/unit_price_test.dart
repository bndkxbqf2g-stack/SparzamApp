import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/catalog/unit_price.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  test('500 g wird als Kilogramm-Grundpreis berechnet', () {
    const product = Product(
      id: 'coffee',
      name: 'Kaffee',
      unit: '500 g',
      group: 'kaffee',
      packageAmount: 500,
      packageUnit: 'g',
    );

    expect(baseUnitPrice(product, 4.99), closeTo(9.98, 0.001));
    expect(baseUnitPriceLabel(product, 4.99), '9.98 €/kg');
  });

  test('750 ml wird als Liter-Grundpreis berechnet', () {
    const product = Product(
      id: 'juice',
      name: 'Saft',
      unit: '750 ml',
      group: 'getraenke',
      packageAmount: 750,
      packageUnit: 'ml',
    );

    expect(baseUnitPrice(product, 2.25), closeTo(3.0, 0.001));
    expect(baseUnitPriceLabel(product, 2.25), '3.00 €/l');
  });

  test('Stückpreis bleibt pro Stück', () {
    const product = Product(
      id: 'eggs',
      name: 'Eier',
      unit: '10 Stk',
      group: 'eier',
      packageAmount: 10,
      packageUnit: 'st',
    );

    expect(baseUnitPrice(product, 2.99), closeTo(0.299, 0.001));
    expect(baseUnitPriceLabel(product, 2.99), '0.30 €/Stk');
  });

  test('ohne Packungsgröße gibt es keinen Grundpreis', () {
    const product = Product(
      id: 'x',
      name: 'Unbekannt',
      unit: 'Artikel',
      group: 'custom',
    );

    expect(baseUnitPrice(product, 1.99), isNull);
    expect(baseUnitPriceLabel(product, 1.99), isNull);
  });
}
