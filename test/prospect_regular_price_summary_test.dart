import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/prospect_regular_price_persistence.dart';
import 'package:sparzamapp/models/price_observation.dart';

void main() {
  final observedAt = DateTime(2026, 10, 15, 12);

  PriceObservation regular({
    required String id,
    required String storeName,
    String? branchId,
  }) =>
      PriceObservation(
        id: id,
        productId: 'coffee-500',
        storeName: storeName,
        locationId: branchId,
        price: 7.99,
        observedAt: observedAt,
        source: PriceObservationSource.retailerWebsite,
        sourceAdapter: 'kaufda',
        kind: PriceObservationKind.regular,
        proofRef: 'https://example.test/proof/$id',
      );

  test('keeps persisted regular counts separate for same-name branches', () {
    final branchA = regular(
      id: 'a',
      storeName: 'Lidl',
      branchId: 'Lidl-Zellingen',
    );
    final branchB = regular(
      id: 'b',
      storeName: 'Lidl',
      branchId: 'Lidl-Wuerzburg',
    );
    final storeOnly = regular(id: 'c', storeName: 'Kaufland');
    final legacyOffer = PriceObservation(
      id: 'legacy-offer',
      productId: 'coffee-500',
      storeName: 'Lidl',
      price: 4.99,
      observedAt: observedAt,
      source: PriceObservationSource.retailerWebsite,
      kind: PriceObservationKind.offer,
      discounted: true,
    );

    final summary = summarizePersistedProspectRegularPrices(
      learned: [branchA, branchB, storeOnly],
      stored: [branchA, branchB, storeOnly, legacyOffer],
    );

    expect(summary.count, 3);
    expect(summary.countsByBranch, {
      'Lidl#lidl-zellingen': 1,
      'Lidl#lidl-wuerzburg': 1,
      'Kaufland': 1,
    });
    expect(summary.countsByBranch.containsKey('Lidl'), isFalse);
  });

  test('does not count a regular price that was not written', () {
    final learned = regular(
      id: 'learned-only',
      storeName: 'Lidl',
      branchId: 'lidl-zellingen',
    );
    final summary = summarizePersistedProspectRegularPrices(
      learned: [learned],
      stored: const [],
    );

    expect(summary.count, 0);
    expect(summary.countsByBranch, isEmpty);
  });
}
