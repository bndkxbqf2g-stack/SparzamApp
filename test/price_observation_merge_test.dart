import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/price_observation_merge.dart';
import 'package:sparzamapp/models/price_observation.dart';

void main() {
  PriceObservation observation(String id, double price) => PriceObservation(
        id: id,
        productId: 'milk',
        storeName: 'Lidl',
        price: price,
        observedAt: DateTime(2026, 10, 13),
        source: PriceObservationSource.manual,
      );

  test('retains concurrent append-only observations and lets loaded IDs win', () {
    final merged = mergePriceObservations(
      [observation('receipt', 1.19), observation('shared', 2)],
      [observation('shared', 1.99), observation('offer', 0.99)],
    );

    expect(merged.map((item) => item.id), ['receipt', 'shared', 'offer']);
    expect(merged.firstWhere((item) => item.id == 'shared').price, 1.99);
  });
}
