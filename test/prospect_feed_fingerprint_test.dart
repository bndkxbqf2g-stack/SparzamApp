import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/services/prospect_feed_fingerprint.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  final feed = ProspectFeedLoadResult(
    records: [
      OfferImportRecord(
        sourceId: 'day-boundary',
        productLabel: 'Kaffee 500 g',
        storeName: 'Lidl',
        originalPrice: 7.99,
        offerPrice: 4.99,
        validFrom: DateTime(2026, 10, 14),
        validUntil: DateTime(2026, 10, 17),
        proofRef: 'https://example.test/lidl/day-boundary',
      ),
    ],
    refreshedStores: const ['Lidl'],
    generatedAt: DateTime(2026, 10, 14, 8),
  );

  test('keeps an unchanged feed reusable within one calendar day', () {
    final first = prospectFeedFingerprintFor(
      feed,
      now: DateTime(2026, 10, 14, 8),
    );
    final later = prospectFeedFingerprintFor(
      feed,
      now: DateTime(2026, 10, 14, 23, 59),
    );

    expect(later, first);
  });

  test('reprocesses an unchanged feed when the validity day changes', () {
    final before = prospectFeedFingerprintFor(
      feed,
      now: DateTime(2026, 10, 14, 23, 59),
    );
    final after = prospectFeedFingerprintFor(
      feed,
      now: DateTime(2026, 10, 15),
    );

    expect(after, isNot(before));
  });
}
