import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/models/receipt_identity.dart';

void main() {
  test('confirmed product identity is exact-route eligible', () {
    final result = assessReceiptIdentity(
      productId: 'schmand',
      identityConfirmed: true,
      familyKey: 'schmand',
    );

    expect(result.state, ReceiptIdentityState.confirmed);
    expect(result.confidence, 1);
    expect(result.exactRouteEligible, isTrue);
    expect(result.reason, contains('bestätigt'));
  });

  test('automatic product assignment stays provisional', () {
    final result = assessReceiptIdentity(
      productId: 'receipt_auto_1',
      familyKey: 'schmand',
    );

    expect(result.state, ReceiptIdentityState.provisional);
    expect(result.confidence, 0);
    expect(result.exactRouteEligible, isFalse);
    expect(result.reason, contains('nicht bestätigte'));
  });

  test('family-only evidence explains why exact identity is rejected', () {
    final result = assessReceiptIdentity(familyKey: 'hackfleisch');

    expect(result.state, ReceiptIdentityState.familyOnly);
    expect(result.exactRouteEligible, isFalse);
    expect(result.reason, contains('Variante'));
  });

  test('unknown receipt text remains unresolved', () {
    final result = assessReceiptIdentity();

    expect(result.state, ReceiptIdentityState.unresolved);
    expect(result.confidence, 0);
    expect(result.exactRouteEligible, isFalse);
  });
}
