import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/quantity_normalizer.dart';

void main() {
  test('mass quantities normalize to kilograms', () {
    final grams = normalizeQuantity(200, 'g');
    final kilograms = normalizeQuantity(0.5, 'kg');
    expect(grams?.amount, closeTo(0.2, 0.0001));
    expect(kilograms?.amount, closeTo(0.5, 0.0001));
    expect(grams?.dimension, QuantityDimension.mass);
    expect(quantitiesComparable(
      leftAmount: 200, leftUnit: 'g', rightAmount: 500, rightUnit: 'g'), isTrue);
  });

  test('milligrams normalize to kilograms and compare with grams', () {
    final milligrams = normalizeQuantity(250, 'mg');
    expect(milligrams?.amount, closeTo(0.00025, 0.00000001));
    expect(milligrams?.dimension, QuantityDimension.mass);
    expect(quantitiesComparable(
      leftAmount: 250,
      leftUnit: 'mg',
      rightAmount: 0.25,
      rightUnit: 'g',
    ), isTrue);
    expect(
      normalizedUnitPrice(price: 1, amount: 250, unit: 'mg'),
      closeTo(4000, 0.0001),
    );
  });

  test('millilitres and litres are comparable', () {
    expect(quantitiesComparable(
      leftAmount: 500, leftUnit: 'ml', rightAmount: 1, rightUnit: 'l'), isTrue);
    expect(normalizedUnitPrice(price: 0.99, amount: 500, unit: 'ml'),
        closeTo(1.98, 0.0001));
  });

  test('centilitres normalize to litres and compare with millilitres', () {
    expect(quantitiesComparable(
      leftAmount: 20,
      leftUnit: 'cl',
      rightAmount: 200,
      rightUnit: 'ml',
    ), isTrue);
    expect(
      normalizedUnitPrice(price: 1.20, amount: 20, unit: 'cl'),
      closeTo(6, 0.0001),
    );
  });

  test('metric unit spellings normalize to the same package basis', () {
    expect(quantitiesComparable(
      leftAmount: 1000, leftUnit: ' Gramm ',
      rightAmount: 1, rightUnit: 'KG.'), isTrue);
    expect(normalizedUnitPrice(price: 1.25, amount: 500, unit: 'Milliliter'),
        closeTo(2.5, 0.0001));
    expect(quantitiesComparable(
      leftAmount: 1, leftUnit: 'Liter',
      rightAmount: 1000, rightUnit: 'ml'), isTrue);
  });

  test('piece-count spellings normalize but packages stay unknown', () {
    expect(quantitiesComparable(
      leftAmount: 6, leftUnit: 'Stk.',
      rightAmount: 6, rightUnit: 'pieces'), isTrue);
    expect(normalizeQuantity(1, 'Packung'), isNull);
  });

  test('mass and count are not comparable', () {
    expect(quantitiesComparable(
      leftAmount: 200, leftUnit: 'g', rightAmount: 1, rightUnit: 'Stk'), isFalse);
  });

  test('unknown units do not become comparable', () {
    expect(normalizeQuantity(1, 'Packung'), isNull);
    expect(quantitiesComparable(
      leftAmount: 1, leftUnit: 'Packung', rightAmount: 1, rightUnit: 'Stk'), isFalse);
  });
}
