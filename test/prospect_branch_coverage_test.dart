import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/prospects/prospect_feed_status.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  test('keeps same-name prospect branches separate in coverage', () {
    final coverage = calculateProspectCoverage(
      issues: [
        ProspectIssue(
          storeName: 'Lidl',
          title: 'Zellingen',
          pages: const [],
          branchId: 'lidl-zellingen',
          location: 'Zellingen',
          sourceStatus: 'ok',
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 18),
        ),
        ProspectIssue(
          storeName: 'Lidl',
          title: 'Würzburg',
          pages: const [],
          branchId: 'lidl-wuerzburg',
          location: 'Würzburg',
          sourceStatus: 'ok',
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 18),
        ),
      ],
      records: [
        OfferImportRecord(
          sourceId: 'zellingen-butter',
          productLabel: 'Butter 250 g',
          storeName: 'Lidl',
          branchId: 'lidl-zellingen',
          location: 'Zellingen',
          originalPrice: 2.49,
          offerPrice: 1.99,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 18),
          source: 'leaflet',
          proofRef: 'https://example.test/lidl/zellingen/butter',
        ),
        OfferImportRecord(
          sourceId: 'wuerzburg-butter',
          productLabel: 'Butter 250 g',
          storeName: 'Lidl',
          branchId: 'lidl-wuerzburg',
          location: 'Würzburg',
          originalPrice: 2.59,
          offerPrice: 2.09,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 18),
          source: 'leaflet',
          proofRef: 'https://example.test/lidl/wuerzburg/butter',
        ),
      ],
      persistedRegularPriceCounts: const {
        'Lidl#lidl-zellingen': 1,
        'Lidl#lidl-wuerzburg': 0,
      },
      now: DateTime(2026, 10, 14),
    );

    final zellingen = coverage.singleWhere(
      (entry) => entry.branchId == 'lidl-zellingen',
    );
    final wuerzburg = coverage.singleWhere(
      (entry) => entry.branchId == 'lidl-wuerzburg',
    );

    expect(coverage.where((entry) => entry.storeName == 'Lidl'), hasLength(2));
    expect(zellingen.structuredOfferCount, 1);
    expect(zellingen.regularPriceCount, 1);
    expect(zellingen.persistedRegularPriceCount, 1);
    expect(zellingen.location, 'Zellingen');
    expect(wuerzburg.structuredOfferCount, 1);
    expect(wuerzburg.regularPriceCount, 1);
    expect(wuerzburg.persistedRegularPriceCount, 0);
    expect(wuerzburg.location, 'Würzburg');
  });

  test('does not copy a legacy store count across multiple branches', () {
    final coverage = calculateProspectCoverage(
      issues: const [
        ProspectIssue(
          storeName: 'Lidl',
          title: 'Zellingen',
          pages: [],
          branchId: 'lidl-zellingen',
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 18),
        ),
        ProspectIssue(
          storeName: 'Lidl',
          title: 'Würzburg',
          pages: [],
          branchId: 'lidl-wuerzburg',
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 18),
        ),
      ],
      records: const [],
      persistedRegularPriceCounts: const {'Lidl': 1},
      now: DateTime(2026, 10, 14),
    );

    expect(
      coverage
          .where((entry) => entry.branchId != null)
          .every((entry) => entry.persistedRegularPriceCount == null),
      isTrue,
    );
  });
}
