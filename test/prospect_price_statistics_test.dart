import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/prospect_price_statistics.dart';
import 'package:sparzamapp/models/price_observation.dart';

void main() {
  PriceObservation observation(
    String id,
    double price,
    DateTime validUntil, {
    PriceObservationKind kind = PriceObservationKind.offer,
    String storeName = 'Netto',
    String productId = 'coffee-500',
  }) => PriceObservation(
    id: id,
    productId: productId,
    storeName: storeName,
    price: price,
    quantity: 500,
    unit: 'g',
    observedAt: DateTime(2026, 9, 30),
    source: PriceObservationSource.leaflet,
    kind: kind,
    validUntil: validUntil,
    proofRef: 'https://example.test/$id',
  );

  test('median of past offers is historical context, not a current offer', () {
    final summaries = prospectPriceHistorySummaries([
      observation('old-1', 5, DateTime(2026, 9, 20)),
      observation('old-2', 6, DateTime(2026, 9, 27)),
      observation(
        'regular',
        8,
        DateTime(2026, 9, 27),
        kind: PriceObservationKind.regular,
      ),
      observation('current', 4, DateTime(2026, 10, 3)),
    ], now: DateTime(2026, 9, 30));

    final summary = summaries['coffee-500']!;
    expect(summary.medianPrice, 5.5);
    expect(summary.kind, PriceObservationKind.offer);
    expect(summary.latestValidUntil, DateTime(2026, 9, 27));
    expect(summary.observationCount, 2);
  });

  test('disabled markets and old claims do not produce price hints', () {
    final summaries = prospectPriceHistorySummaries(
      [
        observation('disabled', 5, DateTime(2026, 9, 27)),
        observation('too-old', 4, DateTime(2026, 5, 1), storeName: 'Lidl'),
      ],
      now: DateTime(2026, 9, 30),
      enabledStores: const ['Lidl'],
    );

    expect(summaries, isEmpty);
  });

  test('legacy prospect evidence without a pack basis cannot set a median', () {
    final summaries = prospectPriceHistorySummaries([
      PriceObservation(
        id: 'old-legacy',
        productId: 'coffee-500',
        storeName: 'Netto',
        price: 5,
        observedAt: DateTime(2026, 9, 20),
        source: PriceObservationSource.leaflet,
        kind: PriceObservationKind.offer,
        validUntil: DateTime(2026, 9, 27),
        proofRef: 'https://example.test/old-legacy',
      ),
    ], now: DateTime(2026, 9, 30));
    expect(summaries, isEmpty);
  });

  test('large prospect history can be summarized by product', () {
    final observations = [
      for (var i = 0; i < 1600; i++)
        observation(
          'offer-$i',
          1 + (i % 10) / 10,
          DateTime(2026, 9, 27),
          productId: 'item-${i % 200}',
        ),
    ];
    final summaries = prospectPriceHistorySummaries(
      observations,
      now: DateTime(2026, 9, 30),
    );
    expect(summaries, hasLength(200));
    expect(summaries['item-0']!.observationCount, 8);
  });
}
