import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/purchase_amount.dart';

void main() {
  test('Komma und Null sind gültige Beträge', () {
    expect(parsePurchaseAmount(' 1,25 '), 1.25);
    expect(parsePurchaseAmount('0'), 0);
  });

  test('leere, negative und nicht endliche Beträge werden verworfen', () {
    expect(parsePurchaseAmount(''), isNull);
    expect(parsePurchaseAmount('-1'), isNull);
    expect(parsePurchaseAmount('NaN'), isNull);
    expect(parsePurchaseAmount('Infinity'), isNull);
  });
}
