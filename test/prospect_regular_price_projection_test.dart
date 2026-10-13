import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/market_price_observation_adapter.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/market_price.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  test('projects a current regular prospect observation as a prospect price', () {
    final observation = PriceObservation(
      id: 'prospect|leaflet|lidl|coffee|regular',
      productId: 'coffee-500',
      storeName: 'Lidl',
      price: 6.99,
      observedAt: DateTime(2026, 10, 14, 8),
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.regular,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      proofRef: 'https://example.test/lidl/coffee',
    );

    final projected = marketPricesFromObservations([observation], now: now);

    expect(projected, hasLength(1));
    expect(projected.single.source, MarketPriceSource.prospect);
    expect(projected.single.sourceLabel, 'Prospekt');
    expect(projected.single.price, 6.99);
    expect(
      projected.single.isUsable(now: now, openPricesMaxAgeDays: 60),
      isTrue,
    );
  });

  test('does not project a prospect offer observation into a regular price', () {
    final observation = PriceObservation(
      id: 'prospect|leaflet|lidl|coffee|offer',
      productId: 'coffee-500',
      storeName: 'Lidl',
      price: 4.99,
      observedAt: DateTime(2026, 10, 14, 8),
      source: PriceObservationSource.leaflet,
      kind: PriceObservationKind.offer,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      proofRef: 'https://example.test/lidl/coffee',
    );

    expect(marketPricesFromObservations([observation], now: now), isEmpty);
  });
}
