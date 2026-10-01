import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/offers/offers_screen.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
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
              pages: const <ProspectPage>[],
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
              pages: const <ProspectPage>[],
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
      expect(find.text('Zellingen · 1 Angebote'), findsOneWidget);
      await tester.tap(find.text('Weitere Angebote'));
      await tester.pumpAndSettle();

      expect(find.text('Sonderartikel 750g'), findsOneWidget);
      final addButton = find.byTooltip('Zur Einkaufsliste');
      expect(addButton, findsOneWidget);
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
}
