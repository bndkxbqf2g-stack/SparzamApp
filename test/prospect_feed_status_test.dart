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
            ProspectFeedStatusCard(
              generatedAt: DateTime(2026, 10, 1, 12, 2),
              now: DateTime(2026, 10, 1, 12, 3),
              regularPriceCount: 2,
            ),
            ProspectFeedStatusCard(fromCache: true),
          ],
        ),
      ),
    );

    expect(find.text('Aktueller Prospektstand'), findsOneWidget);
    expect(find.text('Letzter geprüfter Prospektstand'), findsOneWidget);
    expect(find.textContaining('01.10.2026 · 12:02 Uhr'), findsOneWidget);
    expect(find.textContaining('2 reguläre Normalpreise als Preisbasis gespeichert.'), findsOneWidget);
    expect(
      find.textContaining('abgelaufene Angebote bleiben ausgeblendet'),
      findsOneWidget,
    );
  });

  testWidgets('marks an old cached prospect feed as stale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectFeedStatusCard(
          generatedAt: DateTime(2026, 10, 1, 12, 2),
          now: DateTime(2026, 10, 3, 12, 3),
          fromCache: true,
        ),
      ),
    );

    expect(find.text('Prospektstand veraltet'), findsOneWidget);
    expect(find.textContaining('älter als 48 Stunden'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });

  testWidgets('offers a manual refresh before and after the first feed load', (
    tester,
  ) async {
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectFeedStatusCard(
          onRefresh: () async => refreshes++,
        ),
      ),
    );

    expect(find.text('Prospektstand noch nicht geladen'), findsOneWidget);
    final refresh = find.byTooltip('Prospekte aktualisieren');
    expect(refresh, findsOneWidget);
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(refreshes, 1);
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
      persistedRegularPriceCounts: const {'Kaufland': 1},
      records: [
        OfferImportRecord(
          sourceId: 'aldi-1',
          productLabel: 'Milch',
          storeName: 'ALDI Süd',
          offerPrice: 0.95,
          validUntil: DateTime(2026, 10, 7),
          imageUrl: 'https://example.test/milch',
          proofRef: 'https://example.test/milch-proof',
          category: 'Milchprodukte',
        ),
        OfferImportRecord(
          sourceId: 'edeka-1',
          productLabel: 'Butter',
          storeName: 'EDEKA',
          offerPrice: 1.99,
          validUntil: DateTime(2026, 10, 7),
          category: 'Milchprodukte',
          regionalOnly: true,
        ),
        OfferImportRecord(
          sourceId: 'netto-1',
          productLabel: 'Saft',
          storeName: 'Netto',
          offerPrice: 1.49,
          validUntil: DateTime(2026, 10, 7),
          proofRef: 'javascript:alert(1)',
        ),
        OfferImportRecord(
          sourceId: 'kaufland-1',
          productLabel: 'Kaffee 500 g',
          storeName: 'Kaufland',
          originalPrice: 7.99,
          offerPrice: 4.99,
          validUntil: DateTime(2026, 10, 7),
          proofRef: 'leaflet:kaufland:2026-10-11:p3',
        ),
      ],
    );

    expect(coverage, hasLength(configuredProspectStores.length));
    final aldi = coverage.firstWhere((entry) => entry.storeName == 'ALDI Süd');
    expect(aldi.structuredOfferCount, 1);
    expect(aldi.offerImageCount, 1);
    expect(aldi.offerCategoryCount, 1);
    expect(aldi.offerProofCount, 1);
    expect(aldi.pageCount, 1);
    expect(aldi.hasBranch, isTrue);
    expect(aldi.hasLocation, isTrue);
    expect(aldi.hasAddress, isFalse);
    expect(aldi.hasValidity, isTrue);
    expect(aldi.persistedRegularPriceCount, 0);

    final edeka = coverage.firstWhere((entry) => entry.storeName == 'EDEKA');
    expect(edeka.structuredOfferCount, 1);
    expect(edeka.regionalOnlyCount, 1);
    expect(edeka.routeableOfferCount, 0);
    expect(edeka.offerProofCount, 0);
    expect(edeka.pageCount, 0);
    expect(edeka.sourceStatus, 'metadata_only');
    expect(edeka.availableStoreSignals, 0);

    final netto = coverage.firstWhere((entry) => entry.storeName == 'Netto');
    expect(netto.structuredOfferCount, 1);
    expect(netto.offerProofCount, 0);

    final kaufland = coverage.firstWhere(
      (entry) => entry.storeName == 'Kaufland',
    );
    expect(kaufland.structuredOfferCount, 1);
    expect(kaufland.offerProofCount, 1);
    expect(kaufland.regularPriceCount, 1);
    expect(kaufland.persistedRegularPriceCount, 1);
  });

  test('does not count an equal offer amount as a regular price', () {
    final coverage = calculateProspectCoverage(
      issues: const <ProspectIssue>[],
      records: [
        OfferImportRecord(
          sourceId: 'equal-regular',
          productLabel: 'Butter 250 g',
          storeName: 'Lidl',
          originalPrice: 1.99,
          offerPrice: 1.99,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 18),
          source: 'retailerWebsite',
          branchId: 'lidl-zellingen',
          proofRef: 'https://example.test/lidl/equal-regular',
        ),
      ],
      now: DateTime(2026, 10, 14),
    );

    expect(
      coverage.firstWhere((entry) => entry.storeName == 'Lidl').regularPriceCount,
      0,
    );
  });

  test('filters stale records and dated prospects at the coverage boundary', () {
    final coverage = calculateProspectCoverage(
      issues: [
        ProspectIssue(
          storeName: 'Lidl',
          title: 'Alter Prospekt',
          pages: const [
            ProspectPage(
              number: 1,
              imageUrl: 'https://example.test/old-cover.jpg',
            ),
          ],
          validFrom: DateTime(2026, 9, 1),
          validUntil: DateTime(2026, 9, 7),
        ),
      ],
      records: [
        OfferImportRecord(
          sourceId: 'old-offer',
          productLabel: 'Butter 250 g',
          storeName: 'Lidl',
          offerPrice: 1.29,
          validFrom: DateTime(2026, 9, 1),
          validUntil: DateTime(2026, 9, 7),
          imageUrl: 'https://example.test/old-offer.jpg',
          category: 'Milchprodukte',
        ),
      ],
      now: DateTime(2026, 10, 14),
    );

    final lidl = coverage.firstWhere((entry) => entry.storeName == 'Lidl');
    expect(lidl.structuredOfferCount, 0);
    expect(lidl.pageCount, 0);
    expect(lidl.offerImageCount, 0);
    expect(lidl.offerCategoryCount, 0);
  });

  test('counts a validated cover fallback as one image page', () {
    final coverage = calculateProspectCoverage(
      issues: const [
        ProspectIssue(
          storeName: 'Netto',
          title: 'Wochenprospekt',
          pages: [],
          thumbnailUrl: 'https://cdn.example/netto-cover.jpg',
        ),
        ProspectIssue(
          storeName: 'PENNY',
          title: 'Ungültiger Coverlink',
          pages: [],
          thumbnailUrl: 'javascript:alert(1)',
        ),
      ],
      records: const [],
    );

    expect(
      coverage.firstWhere((entry) => entry.storeName == 'Netto').pageCount,
      1,
    );
    expect(
      coverage.firstWhere((entry) => entry.storeName == 'PENNY').pageCount,
      0,
    );
  });

  testWidgets('shows per-market prospect coverage details when expanded', (
    tester,
  ) async {
    final coverage = calculateProspectCoverage(
      persistedRegularPriceCounts: const {'ALDI Süd': 1},
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
          originalPrice: 1.19,
          offerPrice: 0.95,
          validUntil: DateTime(2026, 10, 7),
          branchId: 'B1',
          proofRef: 'https://example.test/aldi/milch',
          category: 'Milchprodukte',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ListView(children: [ProspectCoverageCard(coverage: coverage)]),
      ),
    );

    expect(find.text('Datenabdeckung der aktuellen Prospekte'), findsOneWidget);
    expect(find.textContaining('1 mit Originalnachweis'), findsOneWidget);
    expect(find.textContaining('0/1 mit Artikelbildern'), findsOneWidget);
    expect(find.textContaining('1/1 mit Kategorien'), findsOneWidget);
    expect(find.text('ALDI Süd'), findsNothing);
    await tester.tap(find.text('Datenabdeckung der aktuellen Prospekte'));
    await tester.pumpAndSettle();
    expect(find.text('ALDI Süd'), findsOneWidget);
    expect(find.textContaining('1 strukturierte Angebote'), findsOneWidget);
    expect(find.textContaining('1/1 Nachweise'), findsOneWidget);
    expect(find.textContaining('1/1 Normalpreise'), findsOneWidget);
    expect(find.textContaining('1 mit gespeichertem Normalpreis'), findsOneWidget);
    expect(find.textContaining('1/1 gespeichert'), findsOneWidget);
    expect(find.text('aktuell'), findsOneWidget);
  });

  testWidgets(
    'marks regional-only prospect coverage separately',
    (tester) async {
      final coverage = calculateProspectCoverage(
        issues: [
          ProspectIssue(
            storeName: 'Lidl',
            title: 'KaufDA regional',
            pages: const [],
            sourceStatus: 'regional_only',
          ),
        ],
        records: [
          OfferImportRecord(
            sourceId: 'regional-1',
            productLabel: 'Butter 250 g',
            storeName: 'Lidl',
            offerPrice: 1.29,
            validUntil: DateTime(2026, 10, 17),
            sourceAdapter: 'kaufda',
            regionalOnly: true,
            proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Butter',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ListView(children: [ProspectCoverageCard(coverage: coverage)]),
        ),
      );

      expect(find.textContaining('1 nur regional'), findsOneWidget);
      await tester.tap(find.text('Datenabdeckung der aktuellen Prospekte'));
      await tester.pumpAndSettle();
      expect(find.text('nur regional'), findsOneWidget);
      expect(
        find.textContaining('1 strukturierte Angebote · 1 nur regional'),
        findsOneWidget,
      );
    },
  );

  test('uses a deterministic age threshold for the feed status', () {
    final generatedAt = DateTime(2026, 10, 1, 12, 2);
    expect(
      isProspectFeedStale(
        generatedAt,
        now: DateTime(2026, 10, 3, 12, 2),
      ),
      isFalse,
    );
    expect(
      isProspectFeedStale(
        generatedAt,
        now: DateTime(2026, 10, 3, 12, 3),
      ),
      isTrue,
    );
    expect(
      isProspectFeedStale(
        generatedAt,
        now: DateTime(2026, 9, 30),
      ),
      isFalse,
    );
  });

  testWidgets('explains when the live prospect feed is stale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectFeedStatusCard(
          generatedAt: DateTime(2026, 10, 1, 12, 2),
          now: DateTime(2026, 10, 3, 12, 3),
        ),
      ),
    );

    expect(find.text('Prospektstand veraltet'), findsOneWidget);
    expect(find.textContaining('älter als 48 Stunden'), findsOneWidget);
    expect(find.text('Aktueller Prospektstand'), findsNothing);
  });

}
