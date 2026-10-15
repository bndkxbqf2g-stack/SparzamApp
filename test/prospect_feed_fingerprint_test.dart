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

  test('manual refresh can force an unchanged feed to be processed', () {
    expect(
      shouldProcessProspectFeed(
        previousFingerprint: 'same',
        currentFingerprint: 'same',
      ),
      isFalse,
    );
    expect(
      shouldProcessProspectFeed(
        previousFingerprint: 'same',
        currentFingerprint: 'same',
        force: true,
      ),
      isTrue,
    );
    expect(
      shouldProcessProspectFeed(
        previousFingerprint: null,
        currentFingerprint: 'same',
      ),
      isTrue,
    );
  });

  test('reprocesses when prospect adapter provenance changes', () {
    final first = ProspectFeedLoadResult(
      records: const [],
      refreshedStores: const [],
      prospects: const [
        ProspectIssue(
          storeName: 'Lidl',
          title: 'Prospekt',
          pages: const [],
          sourceAdapter: 'structured_api',
        ),
      ],
    );
    final second = ProspectFeedLoadResult(
      records: const [],
      refreshedStores: const [],
      prospects: const [
        ProspectIssue(
          storeName: 'Lidl',
          title: 'Prospekt',
          pages: const [],
          sourceAdapter: 'kaufda_next_data',
        ),
      ],
    );

    expect(
      prospectFeedFingerprintFor(first, now: DateTime(2026, 10, 15)),
      isNot(prospectFeedFingerprintFor(second, now: DateTime(2026, 10, 15))),
    );
  });

  test('reprocesses when page completeness diagnostics change', () {
    final first = ProspectFeedLoadResult(
      records: const [],
      refreshedStores: const ['EDEKA'],
      prospects: const [
        ProspectIssue(
          storeName: 'EDEKA',
          title: 'Prospekt',
          pages: [
            ProspectPage(number: 1, imageUrl: 'https://example.test/1.jpg'),
          ],
          availablePageCount: 3,
          loadedPageCount: 1,
          missingPageNumbers: [2, 3],
          pageStatus: 'partial',
          pageCountKnown: true,
        ),
      ],
    );
    final second = ProspectFeedLoadResult(
      records: const [],
      refreshedStores: const ['EDEKA'],
      prospects: const [
        ProspectIssue(
          storeName: 'EDEKA',
          title: 'Prospekt',
          pages: [
            ProspectPage(number: 1, imageUrl: 'https://example.test/1.jpg'),
            ProspectPage(number: 2, imageUrl: 'https://example.test/2.jpg'),
            ProspectPage(number: 3, imageUrl: 'https://example.test/3.jpg'),
          ],
          availablePageCount: 3,
          loadedPageCount: 3,
          pageStatus: 'complete',
          pageCountKnown: true,
        ),
      ],
    );

    expect(
      prospectFeedFingerprintFor(first, now: DateTime(2026, 10, 14)),
      isNot(prospectFeedFingerprintFor(second, now: DateTime(2026, 10, 14))),
    );
  });
}
