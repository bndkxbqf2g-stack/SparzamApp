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

  test('millilitres and litres are comparable', () {
    expect(quantitiesComparable(
      leftAmount: 500, leftUnit: 'ml', rightAmount: 1, rightUnit: 'l'), isTrue);
    expect(normalizedUnitPrice(price: 0.99, amount: 500, unit: 'ml'),
        closeTo(1.98, 0.0001));
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
