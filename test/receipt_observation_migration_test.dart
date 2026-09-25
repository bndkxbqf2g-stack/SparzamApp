import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_observation_migration.dart';
import 'package:sparzamapp/models/receipt_observation.dart';

void main() {
  test('stored receipt family is reinterpreted from immutable raw label', () {
    final legacy = ReceiptObservation(
      id: 'receipt-1',
      receiptFingerprint: 'fp',
      rowLine: 1,
      rawLabel: 'KLC Geh. Tomaten',
      familyKey: 'tomaten',
      storeName: 'Kaufland',
      observedAt: DateTime(2026, 9, 20),
      totalPrice: 1.29,
      quantity: 400,
      quantityUnit: 'g',
      unitPrice: 3.225,
      discounted: false,
      productId: 'tomaten-dose',
      identityConfirmed: true,
    );

    final migrated = reinterpretReceiptObservation(legacy);

    expect(migrated.familyKey, 'tomatenkonserve');
    expect(migrated.rawLabel, legacy.rawLabel);
    expect(migrated.totalPrice, legacy.totalPrice);
    expect(migrated.productId, legacy.productId);
    expect(migrated.identityConfirmed, isTrue);
  });
}
