import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/offer.dart';
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
    expect(find.text('Alle Märkte').first, findsOneWidget);
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

    await _scrollProspects(tester);
    await tester.tap(find.textContaining('ALDI Süd').last);
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
    await tester.ensureVisible(find.text('Zur Einkaufsliste'));
    await tester.tap(find.text('Zur Einkaufsliste'));
    await tester.pump();
    expect(added, isTrue);
  });

  testWidgets('searches current prospect articles across markets', (
    tester,
  ) async {
    Product? added;
    final records = [
      OfferImportRecord(
        sourceId: 'lidl-coffee',
        productLabel: 'Jacobs Kaffee Crema 500 g',
        storeName: 'Lidl',
        offerPrice: 4.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        proofRef: 'https://example.test/lidl/coffee',
      ),
      OfferImportRecord(
        sourceId: 'edeka-milk',
        productLabel: 'Frische Vollmilch 1 l',
        storeName: 'EDEKA',
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        proofRef: 'https://example.test/edeka/milk',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: records,
          now: DateTime(2026, 9, 30),
          catalogProducts: const <Product>[],
          onAddProduct: (product) => added = product,
        ),
      ),
    );

    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Prospekte und Artikel durchsuchen',
    );
    await tester.enterText(search, 'Kaffee');
    await tester.pump();

    expect(find.text('1 passende Prospektartikel'), findsOneWidget);
    expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);
    expect(find.text('Frische Vollmilch 1 l'), findsNothing);

    await _scrollProspects(tester, distance: 450);
    await tester.tap(find.byIcon(Icons.add_shopping_cart_outlined));
    expect(added, isNotNull);
    expect(added!.name, 'Jacobs Kaffee Crema 500 g');
    expect(added!.id, startsWith('prospect|'));
  });

  testWidgets('builds large prospect searches lazily', (tester) async {
    final records = [
      for (var index = 0; index < 120; index++)
        OfferImportRecord(
          sourceId: 'search-$index',
          productLabel: 'Milch $index 1 l',
          storeName: 'Lidl',
          offerPrice: 0.99,
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 3),
          proofRef: 'https://example.test/search/$index',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: records,
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Prospekte und Artikel durchsuchen',
    );
    await tester.enterText(search, 'Milch');
    await tester.pump();

    expect(find.text('120 passende Prospektartikel'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('prospect-search-offer-search-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prospect-search-offer-search-119')),
      findsNothing,
    );
  });

  testWidgets('scrolls a larger cover grid without eagerly building every card',
      (tester) async {
    final prospects = [
      for (var index = 0; index < 24; index++)
        ProspectIssue(
          storeName: 'Markt $index',
          title: 'Aktionsprospekt',
               pages: [],
          thumbnailUrl: 'https://example.test/cover-$index.jpg',
          validFrom: DateTime(2026, 9, 28),
          validUntil: DateTime(2026, 10, 3),
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: prospects,
          now: DateTime(2026, 9, 30),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('prospect-grid')), findsOneWidget);
    expect(find.text('Markt 0'), findsWidgets);
    expect(find.text('Markt 23'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Markt 23'),
      450,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Markt 23'), findsWidgets);
  });

  testWidgets('filters current prospect articles by source category', (
    tester,
  ) async {
    final records = [
      OfferImportRecord(
        sourceId: 'lidl-coffee',
        productLabel: 'Jacobs Kaffee Crema 500 g',
        storeName: 'Lidl',
        offerPrice: 4.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        proofRef: 'https://example.test/lidl/coffee',
        category: 'Kaffee & Snacks',
      ),
      OfferImportRecord(
        sourceId: 'edeka-milk',
        productLabel: 'Frische Vollmilch 1 l',
        storeName: 'EDEKA',
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        proofRef: 'https://example.test/edeka/milk',
        category: 'Milchprodukte',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: records,
          now: DateTime(2026, 9, 30),
          catalogProducts: const <Product>[]
        ),
      ),
    );

    await tester.tap(find.text('Kaffee & Snacks'));
    await tester.pump();

    expect(find.text('1 passende Prospektartikel'), findsOneWidget);
    expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);
    expect(find.text('Frische Vollmilch 1 l'), findsNothing);
  });

  testWidgets('shows the source branch on cross-market article results', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: [
            OfferImportRecord(
              sourceId: 'lidl-coffee',
              productLabel: 'Jacobs Kaffee Crema 500 g',
              storeName: 'Lidl',
              offerPrice: 4.99,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              proofRef: 'https://example.test/lidl/coffee',
            ),
          ],
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: [],
              location: 'Zellingen',
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Prospekte und Artikel durchsuchen',
    );
    await tester.enterText(search, 'Kaffee');
    await tester.pump();

    expect(find.text('Lidl'), findsWidgets);
    expect(find.text('Zellingen'), findsOneWidget);
    expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);
  });

  testWidgets('filters current prospect articles by market', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: [
            OfferImportRecord(
              sourceId: 'lidl-coffee',
              productLabel: 'Jacobs Kaffee Crema 500 g',
              storeName: 'Lidl',
              offerPrice: 4.99,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              proofRef: 'https://example.test/lidl/coffee',
            ),
            OfferImportRecord(
              sourceId: 'edeka-milk',
              productLabel: 'Frische Vollmilch 1 l',
              storeName: 'EDEKA',
              offerPrice: 0.99,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              proofRef: 'https://example.test/edeka/milk',
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    await tester.tap(find.text('Lidl'));
    await tester.pump();

    expect(find.text('1 passende Prospektartikel'), findsOneWidget);
    expect(find.text('Jacobs Kaffee Crema 500 g'), findsOneWidget);
    expect(find.text('Frische Vollmilch 1 l'), findsNothing);
  });

  testWidgets('labels a cached prospect feed clearly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
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

  testWidgets('refreshes the prospect feed from the prospects screen', (
    tester,
  ) async {
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: const [],
          onRefreshProspects: () async => refreshes++,
        ),
      ),
    );

    final refresh = find.byTooltip('Prospekte aktualisieren');
    expect(refresh, findsOneWidget);
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(refreshes, 1);
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

    await _scrollProspects(tester);
    await tester.tap(find.text('PENNY').last);
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

    await _scrollProspects(tester);
    await tester.tap(find.textContaining('Lidl').last);
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

    await _scrollProspects(tester);
    await tester.tap(find.textContaining('Lidl').last);
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
              pages: [],
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

    expect(find.text('EDEKA').first, findsOneWidget);
    expect(
      find.text('Keine aktuell gültigen Angebotsdaten geladen.'),
      findsOneWidget,
    );
    await _scrollProspects(tester);
    await tester.tap(find.text('EDEKA').last);
    await tester.pumpAndSettle();
    expect(find.text('Offiziellen Prospekt öffnen'), findsOneWidget);
  });

  testWidgets('shows a source thumbnail as the cover page in the viewer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'Netto',
              title: 'Netto Wochenprospekt',
              pages: [],
              thumbnailUrl: 'https://example.test/netto-cover.jpg',
              validFrom: DateTime(2026, 10, 12),
              validUntil: DateTime(2026, 10, 17),
            ),
          ],
          now: DateTime(2026, 10, 13),
        ),
      ),
    );

    await _scrollProspects(tester);
    await tester.tap(find.text('Netto').last);
    await tester.pumpAndSettle();

    expect(find.text('Prospektseiten (1)'), findsOneWidget);
    expect(find.text('Seite 1'), findsOneWidget);
  });

  testWidgets('adds a manually reviewed article from a prospect page', (
    tester,
  ) async {
    Offer? saved;
    Product? added;
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: [
                ProspectPage(
                  number: 4,
                  imageUrl: 'https://example.test/lidl/page-4.png',
                ),
              ],
              branchId: 'L-42',
              location: 'Zellingen',
              address: 'Hauptstraße 1, 97225 Zellingen',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 12, 31),
              sourceStatus: 'ok',
            ),
          ],
          now: DateTime(2026, 9, 30),
          onAddProduct: (product) => added = product,
          onSaveOffer: (offer) async {
            saved = offer;
            return [offer];
          },
        ),
      ),
    );

    await _scrollProspects(tester);
    await tester.tap(find.text('Lidl').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artikel von Seite hinzufügen'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Kaffee Crema 500 g');
    await tester.enterText(fields.at(1), '4,99');
    await tester.enterText(fields.at(2), '5,99');
    await tester.tap(find.widgetWithText(FilledButton, 'Artikel hinzufügen'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.id, startsWith('manual-page|'));
    expect(saved!.productId, startsWith('prospect|'));
    expect(saved!.offerPrice, 4.99);
    expect(saved!.originalPrice, 5.99);
    expect(saved!.proofRef, 'https://example.test/lidl/page-4.png');
    expect(saved!.locationId, 'L-42');
    expect(saved!.region, 'Zellingen');
    expect(saved!.address, 'Hauptstraße 1, 97225 Zellingen');
    expect(added?.name, 'Kaffee Crema 500 g');
  });

  testWidgets('hides an invalid official prospect link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: const [],
              url: 'javascript:alert(1)',
              sourceStatus: 'no_current_offers',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    await _scrollProspects(tester);
    await tester.tap(find.text('Lidl').last);
    await tester.pumpAndSettle();

    expect(find.text('Offiziellen Prospekt öffnen'), findsNothing);
    expect(
      find.text('Keine aktuell gültigen Angebotsdaten geladen.'),
      findsOneWidget,
    );
  });

  testWidgets('labels regional-only prospect sources in the overview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: [
            OfferImportRecord(
              sourceId: 'regional-overview',
              productLabel: 'Butter 250 g',
              storeName: 'Lidl',
              offerPrice: 1.29,
              validUntil: DateTime(2026, 10, 17),
              sourceAdapter: 'kaufda',
              regionalOnly: true,
              proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Butter',
            ),
          ],
          prospects: const [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'KaufDA regional',
              pages: [],
              sourceStatus: 'regional_only',
              recordCount: 1,
            ),
          ],
          now: DateTime(2026, 10, 12),
        ),
      ),
    );

    expect(
      find.text('Nur regional erkannt · Filiale noch nicht bestätigt.'),
      findsOneWidget,
    );
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
    await _scrollProspects(tester);
    await tester.tap(find.text('Lidl').last);
    await tester.pumpAndSettle();
    expect(find.text('Seite 1'), findsOneWidget);
    expect(find.text('Seite 99'), findsNothing);
    expect(find.text('Aktueller Kaffee'), findsOneWidget);
    expect(find.text('Alter Kaffee'), findsNothing);
  });

  testWidgets('prefers current prospect metadata with available pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          now: DateTime(2026, 10, 13),
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'ALDI Süd',
              title: 'Aktionsprospekt ohne Bildseiten',
              pages: [],
              sourceStatus: 'ok',
              validFrom: DateTime(2026, 10, 12),
              validUntil: DateTime(2026, 10, 17),
            ),
            ProspectIssue(
              storeName: 'ALDI Süd',
              title: 'Aktionsprospekt mit Cover',
              pages: [
                ProspectPage(
                  number: 1,
                  imageUrl: 'https://example.test/aldi-cover.jpg',
                ),
              ],
              sourceStatus: 'ok',
              validFrom: DateTime(2026, 10, 12),
              validUntil: DateTime(2026, 10, 17),
            ),
          ],
        ),
      ),
    );

    await _scrollProspects(tester);
    await tester.tap(find.text('ALDI Süd').last);
    await tester.pumpAndSettle();

    expect(find.text('Prospektseiten (1)'), findsOneWidget);
    expect(find.text('Aktionsprospekt mit Cover'), findsOneWidget);
    expect(find.text('Aktionsprospekt ohne Bildseiten'), findsNothing);
  });

    testWidgets('shows the record location in prospect search results', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: [
            OfferImportRecord(
              sourceId: 'record-location',
              productLabel: 'Kaffee Crema 500 g',
              storeName: 'Lidl',
              offerPrice: 4.99,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              proofRef: 'https://example.test/record-location',
              location: 'Filialstadt',
              address: 'Filialstraße 1, 97291 Filialstadt',
            ),
          ],
          prospects: const [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: [],
              location: 'Quellstadt',
            ),
          ],
          now: DateTime(2026, 9, 30),
          catalogProducts: const <Product>[],
        ),
      ),
    );

    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Prospekte und Artikel durchsuchen',
    );
    await tester.enterText(search, 'Kaffee');
    await tester.pump();

    expect(find.text('Filialstadt'), findsOneWidget);
    expect(find.text('Filialstraße 1, 97291 Filialstadt'), findsOneWidget);
    expect(find.text('Quellstadt'), findsNothing);
  });
}

Future<void> _scrollProspects(
  WidgetTester tester, {
  double distance = 320,
}) async {
  final scrollable = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
  await tester.drag(scrollable.first, Offset(0, -distance));
  await tester.pumpAndSettle();
}


