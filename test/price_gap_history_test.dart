import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/price_gaps/price_gap_history.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const coffee = Product(
    id: 'coffee',
    name: 'Kaffee',
    unit: '500 g',
    group: 'kaffee',
    packageAmount: 500,
    packageUnit: 'g',
  );
  const tea = Product(id: 'tea', name: 'Tee', unit: '40 Beutel', group: 'tee');

  PriceObservation observation({
    required String id,
    required String? productId,
    required double price,
    double identityConfidence = 1,
    PriceObservationKind kind = PriceObservationKind.unknown,
    bool discounted = false,
    double? quantity,
    String? unit,
    DateTime? observedAt,
  }) => PriceObservation(
    id: id,
    productId: productId,
    familyKey: productId == null ? 'kaffee' : null,
    storeName: 'Kaufland',
    price: price,
    observedAt: observedAt ?? DateTime(2026, 9, 20),
    source: PriceObservationSource.receipt,
    identityConfidence: identityConfidence,
    kind: kind,
    discounted: discounted,
    quantity: quantity,
    unit: unit,
  );

  test('uses only exact regular comparable history for the median', () {
    final levels = historicalPriceLevelsByProduct(
      items: [
        ListItem(product: coffee),
        ListItem(product: tea),
      ],
      observations: [
        observation(id: 'regular-1', productId: 'coffee', price: 8.50),
        observation(id: 'regular-2', productId: 'coffee', price: 9.50),
        observation(
          id: 'offer',
          productId: 'coffee',
          price: 1.00,
          kind: PriceObservationKind.offer,
          discounted: true,
        ),
        observation(id: 'family', productId: null, price: 99),
        observation(
          id: 'uncertain',
          productId: 'coffee',
          price: 100,
          identityConfidence: 0.5,
        ),
        observation(
          id: 'wrong-pack',
          productId: 'coffee',
          price: 100,
          quantity: 1,
          unit: 'kg',
        ),
        observation(
          id: 'future',
          productId: 'coffee',
          price: 100,
          observedAt: DateTime(2026, 10, 2),
        ),
      ],
      now: DateTime(2026, 10, 1),
    );

    expect(levels, {'coffee': 9.0});
    expect(levels.containsKey('tea'), isFalse);
  });
}
