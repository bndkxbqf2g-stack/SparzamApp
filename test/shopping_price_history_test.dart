import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_price_history.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const milk = Product(
    id: 'milk-35',
    name: 'Vollmilch 3,5 %',
    unit: '1 l',
    group: 'milch',
  );
  final now = DateTime(2026, 10, 2, 12);

  PriceObservation observation({
    required String id,
    required String store,
    required double price,
    required DateTime observedAt,
    double confidence = 1,
    PriceObservationKind kind = PriceObservationKind.regular,
  }) => PriceObservation(
    id: id,
    productId: milk.id,
    storeName: store,
    price: price,
    observedAt: observedAt,
    source: PriceObservationSource.leaflet,
    kind: kind,
    validUntil: DateTime(2026, 9, 30),
    quantity: 1,
    unit: 'l',
    identityConfidence: confidence,
    proofRef: 'https://example.test/$id',
  );

  test('shows confirmed exact observations newest first', () {
    final result = shoppingPriceHistory(
      product: milk,
      now: now,
      observations: [
        observation(
          id: 'older',
          store: 'Lidl',
          price: 1.19,
          observedAt: DateTime(2026, 9, 20),
        ),
        observation(
          id: 'newer',
          store: 'ALDI Süd',
          price: 0.99,
          observedAt: DateTime(2026, 10, 1),
          kind: PriceObservationKind.offer,
        ),
        observation(
          id: 'provisional',
          store: 'PENNY',
          price: 0.89,
          observedAt: DateTime(2026, 10, 1),
          confidence: 0,
        ),
        observation(
          id: 'future',
          store: 'Netto',
          price: 0.79,
          observedAt: DateTime(2026, 10, 3),
        ),
      ],
    );

    expect(result, hasLength(2));
    expect(result.first.storeName, 'ALDI Süd');
    expect(result.first.price, 0.99);
    expect(result.first.kindLabel, 'Angebot');
    expect(result.last.storeName, 'Lidl');
  });

  test('limits the visible timeline deterministically', () {
    final result = shoppingPriceHistory(
      product: milk,
      observations: [
        for (var index = 0; index < 4; index++)
          observation(
            id: '$index',
            store: 'Markt $index',
            price: 1 + index / 10,
            observedAt: DateTime(2026, 9, 20 + index),
          ),
      ],
      now: now,
      maxEntries: 2,
    );

    expect(result, hasLength(2));
    expect(result.map((entry) => entry.storeName), ['Markt 3', 'Markt 2']);
  });
}
