import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  testWidgets('shows market prospect cards instead of raw article summary', (
    tester,
  ) async {
    const prospects = [
      ProspectIssue(
        storeName: 'ALDI Süd',
        title: 'Aktionsprospekt',
        pages: [],
        url: 'https://example.test/aldi-prospekt',
        branchId: 'B384',
        location: 'Zellingen',
        address: 'Würzburger Str. 74, 97225 Zellingen, Germany',
        recordCount: 322,
      ),
      ProspectIssue(storeName: 'EDEKA', title: 'Aktionsprospekt', pages: []),
      ProspectIssue(storeName: 'Kaufland', title: 'Aktionsprospekt', pages: []),
      ProspectIssue(storeName: 'Lidl', title: 'Aktionsprospekt', pages: []),
      ProspectIssue(storeName: 'PENNY', title: 'Aktionsprospekt', pages: []),
      ProspectIssue(storeName: 'Netto', title: 'Aktionsprospekt', pages: []),
      ProspectIssue(storeName: 'Netto', title: 'Aktionsprospekt', pages: []),
    ];

    var added = false;
    final records = [
      OfferImportRecord(
        sourceId: 'aldi-berkkaese',
        productLabel: 'Kaiseralm Bergkäse',
        storeName: 'ALDI Süd',
        originalPrice: 2.99,
        offerPrice: 2.39,
        validFrom: DateTime(2026, 9, 21),
        validUntil: DateTime(2026, 9, 26),
        proofRef: 'https://example.test/aldi-berkkaese',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            records: records,
            prospects: prospects,
            onAddProduct: (_) => added = true,
            now: DateTime(2026, 9, 25),
          ),
        ),
      ),
    );

    expect(find.text('Prospekte'), findsOneWidget);
    expect(find.text('Alle Märkte'), findsOneWidget);
    expect(find.text('Zellingen'), findsOneWidget);
    expect(find.text('1 Angebote geladen'), findsOneWidget);
    expect(
      find.text('Aktuelle Prospekte. Produkte antippen und vormerken.'),
      findsOneWidget,
    );
    expect(
      find.text('1854 aktuelle Prospektartikel aus 5 Märkten'),
      findsNothing,
    );

    await tester.tap(find.textContaining('ALDI Süd'));
    await tester.pumpAndSettle();

    expect(find.text('ALDI Süd'), findsWidgets);
    expect(
      find.textContaining('Aktuelle Angebote dieses Marktes'),
      findsOneWidget,
    );
    expect(find.textContaining('Offiziellen Prospekt öffnen'), findsOneWidget);
    expect(find.text('2,39 €'), findsOneWidget);
    expect(find.text('2,99 €'), findsOneWidget);
    expect(find.text('Milchprodukte'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2,39 €'));
    await tester.tap(find.text('2,39 €'));
    await tester.pump();
    expect(added, isTrue);
  });

  testWidgets('labels a cached prospect feed clearly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: const [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: [],
            ),
          ],
          fromCache: true,
        ),
      ),
    );

    expect(find.text('Letzter geprüfter Prospektstand'), findsOneWidget);
    expect(find.textContaining('abgelaufene Angebote'), findsOneWidget);
  });

  testWidgets('kennzeichnet gültige Angebote aus einem Händler-Fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: [
            OfferImportRecord(
              sourceId: 'penny-fallback',
              productLabel: 'MILPRIMA Schmand 200 g',
              storeName: 'PENNY',
              offerPrice: 0.69,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              proofRef: 'https://example.test/penny-fallback',
            ),
          ],
          prospects: const [
            ProspectIssue(
              storeName: 'PENNY',
              title: 'Aktionsprospekt',
              pages: [],
              location: 'Zellingen',
              sourceStatus: 'error',
              recordCount: 232,
              url: 'https://www.penny.de/angebote',
            ),
          ],
          now: DateTime(2026, 10, 1),
        ),
      ),
    );

    expect(
      find.text(
        '1 Angebote aus dem letzten geprüften Prospektstand. '
        'Automatische Aktualisierung aktuell nicht verfügbar.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('PENNY'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Der letzte geprüfte Prospektstand wird verwendet; die automatische '
        'Aktualisierung ist aktuell nicht verfügbar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps official opening action for a browsable prospect', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: const [
                ProspectPage(
                  number: 1,
                  imageUrl: 'https://example.test/page.png',
                ),
              ],
              url: 'https://example.test/official-prospect',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    await tester.tap(find.textContaining('Lidl'));
    await tester.pumpAndSettle();

    expect(find.text('Offiziellen Prospekt öffnen'), findsOneWidget);
  });

  testWidgets('marks a current prospect without structured offers clearly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: const [
                ProspectPage(
                  number: 1,
                  imageUrl: 'https://example.test/page.png',
                ),
              ],
              url: 'https://example.test/official-prospect',
              sourceStatus: 'ok',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    expect(
      find.text('Keine aktuell gültigen Angebotsdaten geladen.'),
      findsOneWidget,
    );

    await tester.tap(find.textContaining('Lidl'));
    await tester.pumpAndSettle();
    expect(find.text('Offiziellen Prospekt öffnen'), findsOneWidget);
  });

  testWidgets('keeps a current metadata-only prospect visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'EDEKA',
              title: 'EDEKA Wochenangebote',
              pages: const [],
              url: 'https://example.test/edeka-prospekt',
              location: 'Zellingen',
              sourceStatus: 'ok',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    expect(find.text('EDEKA'), findsOneWidget);
    expect(
      find.text('Keine aktuell gültigen Angebotsdaten geladen.'),
      findsOneWidget,
    );
    await tester.tap(find.text('EDEKA'));
    await tester.pumpAndSettle();
    expect(find.text('Offiziellen Prospekt öffnen'), findsOneWidget);
  });

  testWidgets('shows current issue and current prices instead of old pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          now: DateTime(2026, 9, 30),
          records: [
            OfferImportRecord(
              sourceId: 'old',
              productLabel: 'Alter Kaffee',
              storeName: 'Lidl',
              offerPrice: 3.99,
              validUntil: DateTime(2026, 9, 27),
            ),
            OfferImportRecord(
              sourceId: 'current',
              productLabel: 'Aktueller Kaffee',
              storeName: 'Lidl',
              offerPrice: 4.99,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Altes Prospekt',
              pages: const [
                ProspectPage(
                  number: 99,
                  imageUrl: 'https://example.test/old-page.png',
                ),
              ],
              validFrom: DateTime(2026, 9, 21),
              validUntil: DateTime(2026, 9, 27),
              recordCount: 99,
            ),
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktuelles Prospekt',
              pages: const [
                ProspectPage(
                  number: 1,
                  imageUrl: 'https://example.test/current-page.png',
                ),
              ],
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              recordCount: 99,
            ),
          ],
        ),
      ),
    );

    expect(find.text('1 Angebote geladen'), findsOneWidget);
    await tester.tap(find.text('Lidl'));
    await tester.pumpAndSettle();
    expect(find.text('Seite 1'), findsOneWidget);
    expect(find.text('Seite 99'), findsNothing);
    expect(find.text('Aktueller Kaffee'), findsOneWidget);
    expect(find.text('Alter Kaffee'), findsNothing);
  });
}
