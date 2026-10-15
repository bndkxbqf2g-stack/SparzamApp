import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/offers/offers_screen.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  testWidgets('begrenzt den äußeren Angebote-Scrollvorlauf', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(catalogProducts: const <Product>[]),
      ),
    );

    final scroll = tester.widget<ListView>(
      find.byKey(const ValueKey('offers-scroll')),
    );
    expect(
      scroll.scrollCacheExtent,
      const ScrollCacheExtent.pixels(0),
    );
  });

  testWidgets(
    'zeigt im Angebotstab nur bestätigte Normalpreisspeicherung an',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OffersScreen(
            catalogProducts: const <Product>[],
            generatedAt: DateTime(2026, 10, 14, 12),
            now: DateTime(2026, 10, 14, 12, 1),
            regularPriceCount: 0,
            prospectRecords: [
              OfferImportRecord(
                sourceId: 'regular-but-not-stored',
                productLabel: 'Butter 250 g',
                storeName: 'Lidl',
                originalPrice: 2.49,
                offerPrice: 1.99,
                validUntil: DateTime(2026, 10, 18),
                branchId: 'lidl-zellingen',
                proofRef: 'https://example.test/lidl/butter',
              ),
            ],
          ),
        ),
      );

      expect(find.textContaining('als Preisbasis gespeichert.'), findsNothing);
    },
  );
  testWidgets('zeigt einen nicht verfügbaren Angebotsfeed transparent an', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectIssues: [
            ProspectIssue(
              storeName: 'Netto',
              title: 'Aktionsprospekt',
               pages: <ProspectPage>[],
              location: 'Thüngersheim',
              sourceStatus: 'error',
              url: 'https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371',
            ),
          ],
          now: DateTime(2026, 10, 1),
        ),
      ),
    );

    expect(find.text('Netto Thüngersheim'), findsOneWidget);
    expect(
      find.text(
        'Automatischer Abruf aktuell nicht verfügbar. Der offizielle Prospekt bleibt direkt erreichbar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Offiziellen Prospekt öffnen'), findsOneWidget);
  });

  testWidgets('blendet ungültige Prospektlink-Schemata aus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectIssues: [
            ProspectIssue(
              storeName: 'KaufDA',
              title: 'Regionaler Treffer',
               pages: <ProspectPage>[],
              sourceStatus: 'error',
              url: 'javascript:alert(1)',
            ),
          ],
          now: DateTime(2026, 10, 1),
        ),
      ),
    );

    expect(find.text('KaufDA'), findsOneWidget);
    expect(find.text('Offiziellen Prospekt öffnen'), findsNothing);
  });

  testWidgets('kennzeichnet gültige Angebote aus einem Feed-Fallback', (
    tester,
  ) async {
    final record = OfferImportRecord(
      sourceId: 'penny-fallback-1',
      productLabel: 'MILPRIMA Schmand 200 g',
      storeName: 'PENNY',
      offerPrice: 0.69,
      validFrom: DateTime(2026, 9, 28),
      validUntil: DateTime(2026, 10, 3),
      proofRef: 'https://example.test/penny-fallback-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectRecords: [record],
          prospectIssues: [
            ProspectIssue(
              storeName: 'PENNY',
              title: 'Aktionsprospekt',
               pages: <ProspectPage>[],
              location: 'Zellingen',
              sourceStatus: 'error',
              recordCount: 1,
              url: 'https://www.penny.de/angebote',
            ),
          ],
          now: DateTime(2026, 10, 1),
        ),
      ),
    );

    expect(
      find.text(
        'Der letzte geprüfte Prospektstand wird verwendet; die automatische '
        'Aktualisierung ist aktuell nicht verfügbar.',
      ),
      findsOneWidget,
    );
    expect(find.text('PENNY'), findsOneWidget);
    expect(
      find.text('Keine aktuell gültigen Angebotsdaten geladen.'),
      findsNothing,
    );
  });

  testWidgets(
    'unbekannter aktueller Prospektartikel kann zur Liste hinzugefügt werden',
    (tester) async {
      Product? added;
      final record = OfferImportRecord(
        sourceId: 'lidl-special-750g',
        productLabel: 'Sonderartikel 750g',
        storeName: 'Lidl',
        originalPrice: 3.49,
        offerPrice: 2.49,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 3),
        proofRef: 'https://example.test/lidl-special-750g',
        location: 'Teststadt',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OffersScreen(
            catalogProducts: const <Product>[],
            prospectRecords: [record],
            now: DateTime(2026, 9, 30),
            onAddToShoppingList: (product) => added = product,
          ),
        ),
      );

      await tester.tap(find.text('Lidl'));
      await tester.pumpAndSettle();
      expect(find.text('Teststadt · 1 Angebote'), findsOneWidget);
      await tester.tap(find.text('Weitere Angebote'));
      await tester.pumpAndSettle();

      expect(find.text('Sonderartikel 750g'), findsOneWidget);
      final addButton = find.byTooltip('Zur Einkaufsliste');
      expect(addButton, findsOneWidget);
      expect(find.byTooltip('Prospektnachweis öffnen'), findsOneWidget);
      await tester.tap(addButton);

      expect(added, isNotNull);
      expect(added!.name, 'Sonderartikel 750g');
      expect(added!.id, startsWith('prospect|'));
      expect(added!.group, 'prospekt');
    },
  );

  testWidgets('Prospektartikel ohne Nachweis bleiben nicht auswählbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectRecords: [
            OfferImportRecord(
              sourceId: 'unproven-special',
              productLabel: 'Unbestätigter Sonderartikel',
              storeName: 'Lidl',
              offerPrice: 2.49,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
            ),
          ],
          now: DateTime(2026, 9, 30),
          onAddToShoppingList: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Lidl'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weitere Angebote'));
    await tester.pumpAndSettle();

    final addButton = find.widgetWithIcon(
      IconButton,
      Icons.add_shopping_cart_outlined,
    );
    expect(addButton, findsOneWidget);
    expect(find.byTooltip('Prospektnachweis öffnen'), findsNothing);
    expect(tester.widget<IconButton>(addButton).onPressed, isNull);
  });

  testWidgets('uses retailer category provenance for offer grouping', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectRecords: [
            OfferImportRecord(
              sourceId: 'source-category',
              productLabel: 'Kaiseralm Bergkäse',
              storeName: 'Lidl',
              offerPrice: 2.39,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              proofRef: 'https://example.test/source-category',
              category: 'Kühlregal',
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    await tester.tap(find.text('Lidl'));
    await tester.pumpAndSettle();
    expect(find.text('Kühlregal'), findsOneWidget);
    expect(find.text('Milchprodukte'), findsNothing);
  });

  testWidgets('formats technical retailer categories for offer grouping', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectRecords: [
            OfferImportRecord(
              sourceId: 'source-category-slug',
              productLabel: 'Kaiseralm Bergkäse',
              storeName: 'Kaufland',
              offerPrice: 2.39,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              proofRef: 'https://example.test/source-category-slug',
              category: '02_Obst__Gemuese__Pflanzen',
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    await tester.tap(find.text('Kaufland'));
    await tester.pumpAndSettle();
    expect(find.text('Obst & Gemüse'), findsOneWidget);
    expect(find.text('02_Obst__Gemuese__Pflanzen'), findsNothing);
  });

  testWidgets('classifies uncategorized coffee offers as coffee and snacks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectRecords: [
            OfferImportRecord(
              sourceId: 'source-coffee',
              productLabel: 'Espresso ganze Bohnen 1 kg',
              storeName: 'EDEKA',
              offerPrice: 8.99,
              validFrom: DateTime(2026, 9, 28),
              validUntil: DateTime(2026, 10, 3),
              proofRef: 'https://example.test/source-coffee',
            ),
          ],
          now: DateTime(2026, 9, 30),
        ),
      ),
    );

    await tester.tap(find.text('EDEKA'));
    await tester.pumpAndSettle();
    expect(find.text('Kaffee & Snacks'), findsOneWidget);
    expect(find.text('Getränke'), findsNothing);
  });

  testWidgets('zeigt den Regionalhinweis auch bei vorhandenen Treffern', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          now: DateTime(2026, 10, 12),
          prospectRecords: [
            OfferImportRecord(
              sourceId: 'regional-offer',
              productLabel: 'Butter 250 g',
              storeName: 'Lidl',
              offerPrice: 1.29,
              validUntil: DateTime(2026, 10, 17),
              sourceAdapter: 'kaufda',
              regionalOnly: true,
              proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Butter',
            ),
          ],
          prospectIssues: const [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'KaufDA regional',
               pages: <ProspectPage>[],
              sourceStatus: 'regional_only',
              recordCount: 1,
            ),
          ],
        ),
      ),
    );

    expect(find.textContaining('nur regional erkannt'), findsOneWidget);
    expect(find.textContaining('für die Route gesperrt'), findsOneWidget);
  });

  testWidgets('leitet Regionalhinweis aus den Datensätzen ab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          now: DateTime(2026, 10, 12),
          prospectRecords: [
            OfferImportRecord(
              sourceId: 'regional-with-ok-source',
              productLabel: 'Butter 250 g',
              storeName: 'Lidl',
              offerPrice: 1.29,
              validUntil: DateTime(2026, 10, 17),
              sourceAdapter: 'kaufda',
              regionalOnly: true,
              proofRef: 'https://www.kaufda.de/Wuerzburg/Angebote/Butter',
            ),
          ],
          prospectIssues: const [
            ProspectIssue(
              storeName: 'Lidl',
              title: 'Offizieller Prospekt',
              pages: <ProspectPage>[],
              sourceStatus: 'ok',
              recordCount: 1,
            ),
          ],
        ),
      ),
    );

    expect(find.textContaining('nur regional erkannt'), findsOneWidget);
    expect(find.textContaining('für die Route gesperrt'), findsOneWidget);
  });
  testWidgets('lädt große Coverlisten seitenweise', (tester) async {
    final issues = [
      for (var index = 1; index <= 13; index++)
        ProspectIssue(
          storeName: 'Markt $index',
          title: 'Aktionsprospekt',
          pages: [
            ProspectPage(
              number: 1,
              imageUrl: 'https://example.test/cover-$index.png',
            ),
          ],
          recordCount: 1,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectIssues: issues,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('offer-cover-open-grid-Markt 13')),
      findsNothing,
    );
    final loadMore = find.byKey(
      const ValueKey('prospect-covers-load-more'),
    );
    expect(loadMore, findsOneWidget);
    tester.widget<OutlinedButton>(loadMore).onPressed!.call();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('offer-cover-open-grid-Markt 13')),
      findsOneWidget,
    );
  });

  testWidgets('trennt Artikelgruppen gleichnamiger Filialen', (tester) async {
    final records = [
      OfferImportRecord(
        sourceId: 'branch-zellingen',
        productLabel: 'Butter 250 g',
        storeName: 'Lidl',
        branchId: 'lidl-zellingen',
        location: 'Zellingen',
        offerPrice: 1.29,
        validUntil: DateTime(2026, 10, 17),
        proofRef: 'https://example.test/lidl/zellingen/butter',
      ),
      OfferImportRecord(
        sourceId: 'branch-wuerzburg',
        productLabel: 'Butter 250 g',
        storeName: 'Lidl',
        branchId: 'lidl-wuerzburg',
        location: 'Würzburg',
        offerPrice: 1.39,
        validUntil: DateTime(2026, 10, 17),
        proofRef: 'https://example.test/lidl/wuerzburg/butter',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectRecords: records,
          now: DateTime(2026, 10, 13),
        ),
      ),
    );

    expect(find.text('Zellingen · 1 Angebote'), findsOneWidget);
    expect(find.text('Würzburg · 1 Angebote'), findsOneWidget);
  });

  testWidgets('lädt Artikelkarten innerhalb einer Kategorie seitenweise', (
    tester,
  ) async {
    final records = [
      for (var index = 1; index <= prospectOfferPageSize + 1; index++)
        OfferImportRecord(
          sourceId: 'paged-$index',
          productLabel: 'Joghurt $index',
          storeName: 'Lidl',
          offerPrice: 0.49,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 17),
          proofRef: 'https://example.test/paged-$index',
          category: 'Kühlregal',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectRecords: records,
          now: DateTime(2026, 10, 13),
        ),
      ),
    );

    await tester.tap(find.text('Lidl'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kühlregal'));
    await tester.pumpAndSettle();

    final lastCard = find.byKey(
      const ValueKey('prospect-offer-Lidl|paged-25'),
    );
    expect(lastCard, findsNothing);
    final loadMore = find.byKey(
      const ValueKey('prospect-load-more-Lidl|Kühlregal'),
    );
    expect(loadMore, findsOneWidget);
    tester.widget<OutlinedButton>(loadMore).onPressed!.call();
    await tester.pump();

    expect(lastCard, findsOneWidget);
  });

  testWidgets(
    'zeigt ein Prospekt mit zukünftigem Startdatum nicht als aktuell',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OffersScreen(
            catalogProducts: const <Product>[],
            now: DateTime(2026, 10, 15),
            prospectIssues: [
              ProspectIssue(
                storeName: 'Zukunftsmarkt',
                title: 'Noch nicht gültig',
                validFrom: DateTime(2026, 10, 16),
                pages: [
                  ProspectPage(
                    number: 1,
                    imageUrl: 'https://example.test/future-cover.jpg',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('offer-cover-open-grid-Zukunftsmarkt'),
        ),
        findsNothing,
      );
    },
  );

}


