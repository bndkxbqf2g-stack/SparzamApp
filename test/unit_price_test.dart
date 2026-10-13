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

  test('20 cl wird als Liter-Grundpreis berechnet', () {
    const product = Product(
      id: 'cream',
      name: 'Sahne',
      unit: '20 cl',
      group: 'milch',
    );

    expect(productQuantity(product)?.amount, 20);
    expect(productQuantity(product)?.unit, 'cl');
    expect(baseUnitPrice(product, 1.20), closeTo(6.0, 0.001));
    expect(baseUnitPriceLabel(product, 1.20), '6.00 €/l');
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

  test('liest eine eindeutige Packungsgröße aus der Produkt-Einheit', () {
    const product = Product(
      id: 'catalog-coffee',
      name: 'Kaffee',
      unit: '4 x 125 g',
      group: 'kaffee',
    );

    final quantity = productQuantity(product);

    expect(quantity?.amount, 500);
    expect(quantity?.unit, 'g');
    expect(baseUnitPriceLabel(product, 4.99), '9.98 €/kg');
  });

  test('lässt uneindeutige Variantenbereiche ohne Packungsbasis offen', () {
    const product = Product(
      id: 'variant-pack',
      name: 'Schokolade',
      unit: '100/95/90 g',
      group: 'süßwaren',
    );

    expect(productQuantity(product), isNull);
    expect(baseUnitPrice(product, 1.99), isNull);
  });

  test('erkennt eine eindeutige Zählpackung als Stückbasis', () {
    const product = Product(
      id: 'yoghurt-pack',
      name: 'Joghurt',
      unit: '3er-Schale',
      group: 'joghurt',
    );

    expect(productQuantity(product)?.amount, 3);
    expect(productQuantity(product)?.unit, 'st');
  });
}
