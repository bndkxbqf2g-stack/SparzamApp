import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/prospects/prospect_feed_status.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  test('formats the feed timestamp for users', () {
    expect(
      formatProspectFeedTimestamp(DateTime(2026, 10, 1, 12, 2)),
      '01.10.2026 · 12:02 Uhr',
    );
    expect(formatProspectFeedTimestamp(null), 'Zeitpunkt unbekannt');
  });

  testWidgets('shows current and cached provenance distinctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            ProspectFeedStatusCard(generatedAt: DateTime(2026, 10, 1, 12, 2)),
            ProspectFeedStatusCard(fromCache: true),
          ],
        ),
      ),
    );

    expect(find.text('Aktueller Prospektstand'), findsOneWidget);
    expect(find.text('Letzter geprüfter Prospektstand'), findsOneWidget);
    expect(find.textContaining('01.10.2026 · 12:02 Uhr'), findsOneWidget);
    expect(
      find.textContaining('abgelaufene Angebote bleiben ausgeblendet'),
      findsOneWidget,
    );
  });

  test('reports prospect evidence without inferring missing fields', () {
    final coverage = calculateProspectCoverage(
      issues: [
        ProspectIssue(
          storeName: 'ALDI Süd',
          title: 'Aktionsprospekt',
          pages: [ProspectPage(number: 1, imageUrl: 'https://example.test/1')],
          sourceStatus: 'ok',
          branchId: 'B1',
          location: 'Zellingen',
          validFrom: DateTime(2026, 10, 1),
          validUntil: DateTime(2026, 10, 7),
        ),
        ProspectIssue(
          storeName: 'EDEKA',
          title: 'Aktionsprospekt',
          pages: [],
          sourceStatus: 'metadata_only',
        ),
      ],
      records: [
        OfferImportRecord(
          sourceId: 'aldi-1',
          productLabel: 'Milch',
          storeName: 'ALDI Süd',
          offerPrice: 0.95,
          validUntil: DateTime(2026, 10, 7),
          imageUrl: 'https://example.test/milch',
          category: 'Milchprodukte',
        ),
      ],
    );

    expect(coverage, hasLength(configuredProspectStores.length));
    final aldi = coverage.firstWhere((entry) => entry.storeName == 'ALDI Süd');
    expect(aldi.structuredOfferCount, 1);
    expect(aldi.offerImageCount, 1);
    expect(aldi.offerCategoryCount, 1);
    expect(aldi.pageCount, 1);
    expect(aldi.hasBranch, isTrue);
    expect(aldi.hasLocation, isTrue);
    expect(aldi.hasAddress, isFalse);
    expect(aldi.hasValidity, isTrue);

    final edeka = coverage.firstWhere((entry) => entry.storeName == 'EDEKA');
    expect(edeka.structuredOfferCount, 0);
    expect(edeka.pageCount, 0);
    expect(edeka.sourceStatus, 'metadata_only');
    expect(edeka.availableStoreSignals, 0);
  });

  testWidgets('shows per-market prospect coverage details when expanded', (
    tester,
  ) async {
    final coverage = calculateProspectCoverage(
      issues: [
        ProspectIssue(
          storeName: 'ALDI Süd',
          title: 'Aktionsprospekt',
          pages: [ProspectPage(number: 1, imageUrl: 'https://example.test/1')],
          sourceStatus: 'ok',
          branchId: 'B1',
          location: 'Zellingen',
          validFrom: DateTime(2026, 10, 1),
          validUntil: DateTime(2026, 10, 7),
        ),
      ],
      records: [
        OfferImportRecord(
          sourceId: 'aldi-1',
          productLabel: 'Milch',
          storeName: 'ALDI Süd',
          offerPrice: 0.95,
          validUntil: DateTime(2026, 10, 7),
          category: 'Milchprodukte',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: ProspectCoverageCard(coverage: coverage)),
    );

    expect(find.text('Datenabdeckung der aktuellen Prospekte'), findsOneWidget);
    expect(find.text('ALDI Süd'), findsNothing);
    await tester.tap(find.text('Datenabdeckung der aktuellen Prospekte'));
    await tester.pumpAndSettle();
    expect(find.text('ALDI Süd'), findsOneWidget);
    expect(find.textContaining('1 strukturierte Angebote'), findsOneWidget);
    expect(find.text('aktuell'), findsOneWidget);
  });
}
