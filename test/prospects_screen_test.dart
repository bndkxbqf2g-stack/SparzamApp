import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';
import 'package:sparzamapp/features/prospects/prospect_cover_section.dart';
import 'package:sparzamapp/features/prospects/prospect_page_ocr.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  test('ignores delayed fallbacks from recycled prospect images', () {
    expect(
      prospectImageFallbackMatches(
        currentUrl: 'https://example.test/new-cover.jpg',
        failedUrl: 'https://example.test/old-cover.jpg',
      ),
      isFalse,
    );
    expect(
      prospectImageFallbackMatches(
        currentUrl: 'https://example.test/current-page.jpg',
        failedUrl: 'https://example.test/current-page.jpg',
      ),
      isTrue,
    );
  });
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
    expect(find.textContaining('1 Angebote geladen'), findsOneWidget);
    expect(find.textContaining('Filiale: B384'), findsOneWidget);
    expect(
      find.text('Aktuelle Prospekte. Produkte antippen und vormerken.'),
      findsOneWidget,
    );
    expect(
      find.text('1854 aktuelle Prospektartikel aus 5 Märkten'),
      findsNothing,
    );

    await _scrollProspects(tester);

    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('prospect-card-grid-ALDI Süd#b384'),
            ),
          )
          .height,
      300,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('prospect-details-grid-ALDI Süd#b384'),
            ),
          )
          .height,
      132,
    );
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

  testWidgets('uses the persistence-confirmed regular price count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            records: [
              OfferImportRecord(
                sourceId: 'stored-count',
                productLabel: 'Butter 250 g',
                storeName: 'Lidl',
                originalPrice: 2.49,
                offerPrice: 1.99,
                validFrom: DateTime(2026, 10, 12),
                validUntil: DateTime(2026, 10, 18),
                branchId: 'lidl-zellingen',
                proofRef: 'https://example.test/lidl/stored-count',
              ),
            ],
            prospects: const [
              ProspectIssue(
                storeName: 'Lidl',
                title: 'Aktionsprospekt',
                pages: [],
              ),
            ],
            generatedAt: DateTime(2026, 10, 14, 12),
            now: DateTime(2026, 10, 14, 13),
            regularPriceCount: 0,
          ),
        ),
      ),
    );

    expect(find.textContaining('als Preisbasis gespeichert.'), findsNothing);
  });

  testWidgets('keeps viewer offer keys unique without source ids', (
    tester,
  ) async {
    var added = 0;
    final records = [
      OfferImportRecord(
        sourceId: '',
        productLabel: 'Kaffee Crema 500 g',
        storeName: 'Lidl',
        offerPrice: 4.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        proofRef: 'https://example.test/lidl/coffee',
      ),
      OfferImportRecord(
        sourceId: '',
        productLabel: 'Milch 1 l',
        storeName: 'Lidl',
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        proofRef: 'https://example.test/lidl/milk',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectViewerScreen(
          issue: ProspectIssue(
            storeName: 'Lidl',
            title: 'Aktionsprospekt',
            pages: const [],
            validFrom: DateTime(2026, 9, 28),
            validUntil: DateTime(2026, 10, 3),
          ),
          records: records,
          catalogProducts: const [],
          now: DateTime(2026, 9, 30),
          onAddProduct: (_) => added++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ).first,
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kaffee Crema 500 g'), findsOneWidget);
    expect(find.text('Milch 1 l'), findsOneWidget);
    await tester.tap(find.text('Zur Einkaufsliste').first);
    expect(added, 1);
  });
  testWidgets('keeps viewer offers bound to the selected branch', (
    tester,
  ) async {
    final records = [
      OfferImportRecord(
        sourceId: 'branch-a',
        productLabel: 'Butter Filiale A',
        storeName: 'Lidl',
        offerPrice: 1.29,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        branchId: 'lidl-zellingen',
        proofRef: 'https://example.test/lidl/zellingen/butter',
      ),
      OfferImportRecord(
        sourceId: 'branch-b',
        productLabel: 'Butter Filiale B',
        storeName: 'Lidl',
        offerPrice: 1.39,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        branchId: 'lidl-wuerzburg',
        proofRef: 'https://example.test/lidl/wuerzburg/butter',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectViewerScreen(
          issue: ProspectIssue(
            storeName: 'Lidl',
            title: 'Aktionsprospekt',
            pages: const [],
            branchId: 'lidl-zellingen',
            validFrom: DateTime(2026, 9, 28),
            validUntil: DateTime(2026, 10, 3),
          ),
          records: records,
          catalogProducts: const [],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Butter Filiale A'), findsOneWidget);
    expect(find.text('Butter Filiale B'), findsNothing);
  });

  testWidgets('search excludes offers from another branch', (tester) async {
    final records = [
      OfferImportRecord(
        sourceId: 'branch-a-search',
        productLabel: 'Milch Filiale A',
        storeName: 'Lidl',
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        branchId: 'lidl-zellingen',
        proofRef: 'https://example.test/lidl/zellingen/milk',
      ),
      OfferImportRecord(
        sourceId: 'branch-b-search',
        productLabel: 'Milch Filiale B',
        storeName: 'Lidl',
        offerPrice: 1.09,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        branchId: 'lidl-wuerzburg',
        proofRef: 'https://example.test/lidl/wuerzburg/milk',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: records,
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: [],
              branchId: 'lidl-zellingen',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
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
    await tester.enterText(search, 'Milch');
    await tester.pump();

    expect(find.text('1 passende Prospektartikel'), findsOneWidget);
    expect(find.text('Milch Filiale A'), findsOneWidget);
    expect(find.text('Milch Filiale B'), findsNothing);
  });

  testWidgets('keeps same-name branches in search results', (tester) async {
    final records = [
      OfferImportRecord(
        sourceId: 'branch-a-multi-search',
        productLabel: 'Milch Filiale A',
        storeName: 'Lidl',
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        branchId: 'lidl-zellingen',
        proofRef: 'https://example.test/lidl/zellingen/milk',
      ),
      OfferImportRecord(
        sourceId: 'branch-b-multi-search',
        productLabel: 'Milch Filiale B',
        storeName: 'Lidl',
        offerPrice: 1.09,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        branchId: 'lidl-wuerzburg',
        proofRef: 'https://example.test/lidl/wuerzburg/milk',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: records,
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt Zellingen',
              pages: const [],
              branchId: 'lidl-zellingen',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt Würzburg',
              pages: const [],
              branchId: 'lidl-wuerzburg',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
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
    await tester.enterText(search, 'Milch');
    await tester.pump();

    expect(find.text('2 passende Prospektartikel'), findsOneWidget);
    expect(find.text('Milch Filiale A'), findsOneWidget);

    // The second exact-branch group is built lazily by the search sliver.
    await _scrollProspects(tester, distance: 500);
    expect(find.text('Milch Filiale B'), findsOneWidget);
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


  testWidgets('sucht auch in quellenbezogenen Produktmetadaten', (
    tester,
  ) async {
    final record = OfferImportRecord(
      sourceId: 'metadata-search',
      productLabel: 'Butter',
      storeName: 'Lidl',
      offerPrice: 1.49,
      validUntil: DateTime(2026, 10, 17),
      proofRef: 'https://example.test/lidl/metadata-search',
      ean: '4001234567890',
      packageSize: '250 g',
      priceByBaseUnit: '5,96 €/kg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: [record],
          now: DateTime(2026, 10, 12),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final search = find.byType(TextField);
    expect(search, findsOneWidget);
    await tester.enterText(search, '4001234567890');
    await tester.pump();

    expect(find.text('1 passende Prospektartikel'), findsOneWidget);
    expect(find.text('Butter'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          key: const ValueKey('package-search'),
          records: [record],
          now: DateTime(2026, 10, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final packageSearch = find.byType(TextField);
    expect(packageSearch, findsOneWidget);
    await tester.enterText(packageSearch, '250 g');
    await tester.pump();

    expect(find.text('1 passende Prospektartikel'), findsOneWidget);
    expect(find.text('Butter'), findsOneWidget);
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

  testWidgets('keeps cross-origin cover cards visible', (
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
              pages: const [],
              thumbnailUrl: 'https://cdn.example.test/lidl-cover.jpg',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );
    await tester.pump();
    await _scrollProspects(tester);

    expect(
      find.byKey(
        const ValueKey('prospect-cover-image-grid-Lidl'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps same-name branch card children keyed independently', (
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
              pages: [],
              branchId: 'lidl-zellingen',
              location: 'Zellingen',
              thumbnailUrl: 'https://example.test/lidl-zellingen.jpg',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: [],
              branchId: 'lidl-wuerzburg',
              location: 'Würzburg',
              thumbnailUrl: 'https://example.test/lidl-wuerzburg.jpg',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('prospect-cover-image-favorite-Lidl#lidl-zellingen'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('prospect-cover-image-favorite-Lidl#lidl-wuerzburg'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prospect-favorite-Lidl#lidl-zellingen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prospect-favorite-Lidl#lidl-wuerzburg')),
      findsOneWidget,
    );

    await _scrollProspects(tester, distance: 500);

    expect(
      find.byKey(
        const ValueKey('prospect-cover-image-grid-Lidl#lidl-zellingen'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('prospect-cover-image-grid-Lidl#lidl-wuerzburg'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prospect-open-grid-Lidl#lidl-zellingen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prospect-open-grid-Lidl#lidl-wuerzburg')),
      findsOneWidget,
    );
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

  testWidgets('hides expired prospect covers from the current card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Abgelaufte Woche',
              pages: const [
                ProspectPage(
                  number: 1,
                  imageUrl: 'https://example.test/expired-cover.jpg',
                ),
              ],
              thumbnailUrl: 'https://example.test/expired-cover.jpg',
              url: 'https://example.test/official-prospect',
              sourceStatus: 'ok',
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          now: DateTime(2026, 10, 13),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey('prospect-cover-image-grid-Lidl'),
      ),
      findsNothing,
    );
    expect(
      find.text('Keine aktuell gültigen Angebotsdaten geladen.'),
      findsOneWidget,
    );

    await _scrollProspects(tester);
    await tester.tap(find.text('Lidl').last);
    await tester.pumpAndSettle();

    expect(find.text('Prospektseiten (1)'), findsNothing);
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


  testWidgets(
    'shows the reported page count separately from bounded image previews',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProspectViewerScreen(
            issue: ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: const [
                ProspectPage(
                  number: 1,
                  imageUrl: 'https://example.test/page-1.jpg',
                ),
                ProspectPage(
                  number: 5,
                  imageUrl: 'https://example.test/page-5.jpg',
                ),
              ],
              availablePageCount: 73,
              loadedPageCount: 2,
              pageCountKnown: true,
              validFrom: DateTime(2026, 10, 12),
              validUntil: DateTime(2026, 10, 17),
            ),
            records: const [],
            catalogProducts: const [],
            now: DateTime(2026, 10, 13),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Prospektseiten (73)'), findsOneWidget);
      expect(
        find.text(
          '2 Bildvorschauen geladen; weitere Seiten beim Händler öffnen.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('keeps prospect page previews bounded for smooth scrolling', (
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
              pages: [
                ProspectPage(
                  number: 7,
                  imageUrl: 'https://example.test/lidl-page-7.png',
                ),
              ],
              validFrom: DateTime(2026, 10, 12),
              validUntil: DateTime(2026, 10, 17),
            ),
          ],
          now: DateTime(2026, 10, 13),
        ),
      ),
    );

    await _scrollProspects(tester);
    await tester.tap(find.text('Lidl').last);
    await tester.pumpAndSettle();

    final viewer = tester.widget<CustomScrollView>(
      find.byKey(const ValueKey('prospect-viewer-scroll')),
    );
    expect(viewer.scrollCacheExtent, isNotNull);

    final preview = tester.widget<Image>(
      find.byKey(const ValueKey('prospect-page-image-7')),
    );
    final provider = preview.image;
    expect(provider, isA<ResizeImage>());
    final resized = provider as ResizeImage;
    expect(resized.width, 720);
    expect(resized.height, 480);
    expect(preview.loadingBuilder, isNull);
    expect(preview.frameBuilder, isNotNull);
  });

  testWidgets('builds long prospect page lists lazily', (tester) async {
    final pages = List<ProspectPage>.generate(
      20,
      (index) => ProspectPage(
        number: index + 1,
        imageUrl: 'https://example.test/lidl-page-${index + 1}.png',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: pages,
              validFrom: DateTime(2026, 10, 12),
              validUntil: DateTime(2026, 10, 17),
            ),
          ],
          now: DateTime(2026, 10, 13),
        ),
      ),
    );

    await _scrollProspects(tester);
    await tester.tap(find.text('Lidl').last);
    await tester.pumpAndSettle();

    final renderedPageImages = tester.allWidgets
        .whereType<Image>()
        .where((widget) {
          final key = widget.key;
          return key is ValueKey<String> &&
              key.value.startsWith('prospect-page-image-');
        })
        .length;
    expect(renderedPageImages, lessThan(pages.length));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('prospect-page-image-20')),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('prospect-page-image-20')),
      findsOneWidget,
    );
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
              sourceAdapter: 'kaufda',
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
    expect(saved!.capturedAt, isNotNull);
    expect(saved!.sourceAdapter, 'kaufda');
    expect(saved!.locationId, 'L-42');
    expect(saved!.region, 'Zellingen');
    expect(saved!.address, 'Hauptstraße 1, 97225 Zellingen');
    expect(saved!.evidenceConfidence, EvidenceConfidence.manuallyConfirmed);
    expect(added?.name, 'Kaffee Crema 500 g');
  });

  testWidgets(
    'adds an unscoped prospect page article to the list without a route price',
    (tester) async {
      Offer? saved;
      Product? added;
      await tester.pumpWidget(
        MaterialApp(
          home: ProspectsScreen(
            records: const [],
            prospects: [
              ProspectIssue(
                storeName: 'Lidl',
                title: 'Regionaler Aktionsprospekt',
                pages: [
                  ProspectPage(
                    number: 2,
                    imageUrl: 'https://example.test/lidl/page-2.png',
                  ),
                ],
                sourceAdapter: 'kaufda',
                location: 'Würzburg',
                validFrom: DateTime(2026, 9, 28),
                validUntil: DateTime(2026, 12, 31),
                sourceStatus: 'regional_only',
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

      expect(saved, isNull);
      expect(added?.name, 'Kaffee Crema 500 g');
      expect(
        find.text(
          'Artikel zur Einkaufsliste hinzugefügt. Für einen Routenpreis '
          'fehlt die exakte Filiale.',
        ),
        findsOneWidget,
      );
    },
  );

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
    await tester.scrollUntilVisible(
      find.text('Aktueller Kaffee'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
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

  testWidgets('übernimmt einen geprüften OCR-Vorschlag in das Seitenformular', (
    tester,
  ) async {
    final validUntil = DateTime.now().add(const Duration(days: 1));
    Product? added;
    Offer? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectViewerScreen(
          issue: ProspectIssue(
            storeName: 'Netto',
            title: 'Aktionsprospekt',
            pages: const [
              ProspectPage(
                number: 1,
                imageUrl: 'https://example.test/netto/page-1.png',
              ),
            ],
            validFrom: DateTime(2026, 10, 12),
            validUntil: validUntil,
          ),
          records: const [],
          catalogProducts: const [],
          onAddProduct: (product) => added = product,
          onSaveOffer: (offer) async {
            saved = offer;
            return [offer];
          },
          ocrRunner: (_) async => ProspectPageOcrResult(
            status: ProspectPageOcrStatus.ready,
            message: '1 Vorschlag gefunden.',
            candidates: const [
              ProspectPageOcrCandidate(
                productLabel: 'Käsesticks 300 g',
                offerPrice: 2.49,
                originalPrice: 3.99,
                confidence: ProspectPageOcrConfidence.medium,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Seite per OCR prüfen'));
    await tester.pump();
    expect(find.textContaining('Lokaler OCR-Vorschlag'), findsOneWidget);

    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'Käsesticks 300 g',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      '2,49',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Artikel hinzufügen'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.source, 'leaflet');
    expect(added, isNotNull);
    expect(added!.name, 'Käsesticks 300 g');
  });

  testWidgets('lässt mehrere OCR-Vorschläge vor dem Formular auswählen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectViewerScreen(
          issue: ProspectIssue(
            storeName: 'Lidl',
            title: 'Aktionsprospekt',
            pages: const [
              ProspectPage(
                number: 2,
                imageUrl: 'https://example.test/lidl/page-2.png',
              ),
            ],
            validFrom: DateTime(2026, 10, 12),
            validUntil: DateTime(2026, 10, 17),
          ),
          records: const [],
          catalogProducts: const [],
          onAddProduct: (_) {},
          onSaveOffer: (offer) async => [offer],
          ocrRunner: (_) async => const ProspectPageOcrResult(
            status: ProspectPageOcrStatus.ready,
            message: '2 Vorschläge gefunden.',
            candidates: [
              ProspectPageOcrCandidate(
                productLabel: 'Kaffee Crema 500 g',
                offerPrice: 4.99,
                confidence: ProspectPageOcrConfidence.high,
              ),
              ProspectPageOcrCandidate(
                productLabel: 'Milch 1 l',
                offerPrice: 0.99,
                confidence: ProspectPageOcrConfidence.medium,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Seite per OCR prüfen'));
    await tester.pumpAndSettle();
    expect(find.text('OCR-Vorschlag auswählen'), findsOneWidget);
    expect(find.text('Kaffee Crema 500 g'), findsOneWidget);
    expect(find.text('Milch 1 l'), findsOneWidget);

    await tester.tap(find.text('Milch 1 l'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'Milch 1 l',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      '0,99',
    );
  });


  testWidgets('begrenzt den Favoritenstreifen beim vertikalen Scrollen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectsScreen(
          records: const [],
          prospects: const [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Aktionsprospekt',
              pages: [],
              thumbnailUrl: 'https://example.test/lidl-cover.jpg',
            ),
            ProspectIssue(
              storeName: 'ALDI Süd',
              title: 'Aktionsprospekt',
              pages: [],
              thumbnailUrl: 'https://example.test/aldi-cover.jpg',
            ),
          ],
        ),
      ),
    );

    final rail = tester.widget<ListView>(
      find.byKey(const ValueKey('prospect-favorite-rail')),
    );
    expect(rail.scrollCacheExtent, const ScrollCacheExtent.pixels(0));
  });

  testWidgets('wärmt einen kurzen Prospekt-Scrollvorlauf vor', (tester) async {
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
        ),
      ),
    );

    final scroll = tester.widget<CustomScrollView>(
      find.byKey(const ValueKey('prospect-bring-scroll')),
    );
    expect(
      scroll.scrollCacheExtent,
      const ScrollCacheExtent.pixels(180),
    );
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


