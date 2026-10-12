import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/models/offer_observation.dart';
import 'package:sparzamapp/services/offer_source.dart';

void main() {
  test('offer observations keep validity and unknown prices explicit', () {
    final observation = OfferObservation(
      market: 'Lidl',
      exactStore: 'lidl_zellingen',
      productFamily: 'milch',
      variant: '3,5 %',
      packageSize: '1 l',
      regularPrice: 1.49,
      offerPrice: 0.99,
      unitPrice: 0.99,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17, 23, 59),
      source: 'fixture',
      capturedAt: DateTime(2026, 10, 12, 8),
    );

    expect(observation.isCurrentAt(DateTime(2026, 10, 13)), isTrue);
    expect(observation.isCurrentAt(DateTime(2026, 10, 18)), isFalse);
    expect(
      const OfferObservation(
        market: 'Lidl',
        productFamily: 'milch',
        source: 'fixture',
        capturedAt: DateTime(2026, 10, 12),
      ).isCurrentAt(DateTime(2026, 10, 13)),
      isFalse,
    );
  });

  test('disabled retailer adapters report unavailable without requests', () async {
    const sources = <OfferSource>[
      LidlOfferSource(),
      KauflandOfferSource(),
    ];

    for (final source in sources) {
      final result = await source.fetchCurrent(
        exactStore: 'fixture-branch',
        now: DateTime(2026, 10, 13),
      );
      expect(source.enabled, isFalse);
      expect(source.source, isNotEmpty);
      expect(result.available, isFalse);
      expect(result.observations, isEmpty);
      expect(result.errorCode, 'source_disabled');
    }
  });

  test('explicitly enabled but unconfigured adapter remains unknown', () async {
    const result = await LidlOfferSource(enabled: true).fetchCurrent(
      exactStore: 'fixture-branch',
    );

    expect(result.available, isFalse);
    expect(result.errorCode, 'adapter_not_configured');
  });
}
