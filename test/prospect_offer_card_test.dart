import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/prospects/prospect_offer_card.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  testWidgets('shows prospect evidence and confirms list transfer', (
    tester,
  ) async {
    var added = false;
    final record = OfferImportRecord(
      sourceId: 'lidl-oat-1',
      productLabel: 'Eigenmarke Haferdrink 1 l',
      storeName: 'Lidl',
      originalPrice: 1.29,
      offerPrice: 0.99,
      validUntil: DateTime(2026, 10, 2),
      source: 'leaflet',
      proofRef: 'https://example.test/lidl/oat-1',
      location: 'Zellingen',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(
            record: record,
            product: const Product(
              id: 'oat',
              name: 'Eigenmarke Haferdrink 1 l',
              unit: '1 l',
              group: 'prospekt',
            ),
            onAdd: () => added = true,
          ),
        ),
      ),
    );

    expect(find.text('0,99 €'), findsOneWidget);
    expect(find.text('Lidl'), findsOneWidget);
    expect(find.text('Zellingen'), findsOneWidget);
    expect(find.text('Gültig bis 02.10.2026'), findsOneWidget);
    expect(find.text('-23 %'), findsOneWidget);

    await tester.tap(find.text('Zur Einkaufsliste'));
    await tester.pump();

    expect(added, isTrue);
    expect(find.text('Hinzugefügt'), findsOneWidget);
  });

  testWidgets('confirms regional prospect as list-only item', (
    tester,
  ) async {
    var added = false;
    final record = OfferImportRecord(
      sourceId: 'regional-kaufda-list-only',
      productLabel: 'Butter 250 g',
      storeName: 'Lidl',
      originalPrice: 1.99,
      offerPrice: 1.49,
      validUntil: DateTime(2026, 10, 18),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      regionalOnly: true,
      proofRef: 'https://example.test/kaufda/butter',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(
            record: record,
            product: const Product(
              id: 'butter-250',
              name: 'Butter 250 g',
              unit: '250 g',
              group: 'milchprodukte',
            ),
            requiresManualConfirmation: true,
            listOnlyWithoutBranch: true,
            onAdd: () => added = true,
          ),
        ),
      ),
    );

    expect(find.text('Prüfen & nur zur Einkaufsliste'), findsOneWidget);
    await tester.tap(find.text('Prüfen & nur zur Einkaufsliste'));
    await tester.pump();

    expect(
      find.textContaining('nur ein regionaler Prospektnachweis'),
      findsOneWidget,
    );
    await tester.tap(find.text('Als Artikel übernehmen'));
    await tester.pump();

    expect(added, isTrue);
    expect(find.text('Hinzugefügt'), findsOneWidget);
  });

  testWidgets('shows the prospect validity start date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(
            record: OfferImportRecord(
              sourceId: 'validity-start',
              productLabel: 'Butter 250 g',
              storeName: 'Lidl',
              offerPrice: 1.49,
              validFrom: DateTime(2026, 10, 12),
              validUntil: DateTime(2026, 10, 18),
              proofRef: 'https://example.test/lidl/validity-start',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Gültig ab 12.10.2026'), findsOneWidget);
    expect(find.text('Gültig bis 18.10.2026'), findsOneWidget);
  });

  testWidgets('asks before adding an unresolved prospect identity', (
    tester,
  ) async {
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(
            record: OfferImportRecord(
              sourceId: 'ambiguous-card',
              productLabel: 'Milch 1 l',
              storeName: 'Lidl',
              offerPrice: 0.99,
              validUntil: DateTime(2026, 10, 2),
              proofRef: 'https://example.test/lidl/ambiguous-card',
            ),
            requiresManualConfirmation: true,
            onAdd: () => added = true,
          ),
        ),
      ),
    );

    final button = find.text('Prüfen & übernehmen');
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Artikelidentität prüfen'), findsOneWidget);
    expect(added, isFalse);
    await tester.tap(find.text('Als Artikel übernehmen'));
    await tester.pumpAndSettle();

    expect(added, isTrue);
    expect(find.text('Hinzugefügt'), findsOneWidget);
  });

  testWidgets('shows a comparable base price when package data is known', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(
            record: OfferImportRecord(
              sourceId: 'milk-1',
              productLabel: 'Milch 1 l',
              storeName: 'Lidl',
              offerPrice: 0.95,
              validUntil: DateTime(2026, 10, 2),
              source: 'leaflet',
              proofRef: 'https://example.test/lidl/milk-1',
            ),
            product: const Product(
              id: 'milk',
              name: 'Milch 1 l',
              unit: '1 l',
              group: 'milch',
              packageAmount: 1,
              packageUnit: 'l',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Grundpreis 0.95 €/l'), findsOneWidget);
  });

  testWidgets('hides hostless proof action', (tester) async {
    final record = OfferImportRecord(
      sourceId: 'hostless-proof',
      productLabel: 'Eigenmarke Haferdrink 1 l',
      storeName: 'Lidl',
      offerPrice: 0.99,
      validUntil: DateTime(2026, 10, 2),
      source: 'leaflet',
      proofRef: 'https://',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(record: record),
        ),
      ),
    );

    expect(find.text('Prospektnachweis öffnen'), findsNothing);
  });

  testWidgets('shows KaufDA provenance and regional limitation', (tester) async {
    final record = OfferImportRecord(
      sourceId: 'regional-kaufda',
      productLabel: 'Butter 250 g',
      storeName: 'Lidl',
      offerPrice: 1.49,
      validUntil: DateTime(2026, 10, 2),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      regionalOnly: true,
      proofRef: 'https://example.test/kaufda/butter',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(record: record, compact: true),
        ),
      ),
    );

    expect(find.text('Quelle KaufDA'), findsOneWidget);
    expect(
      find.text('Nur regional erkannt · Filiale noch nicht bestätigt'),
      findsOneWidget,
    );
    final addButton = find.ancestor(
      of: find.byIcon(Icons.add_shopping_cart_outlined),
      matching: find.byType(IconButton),
    );
    expect(addButton, findsOneWidget);
    expect(
      tester.widget<IconButton>(addButton).onPressed,
      isNull,
    );
  });

  testWidgets('hides an invalid crossed-out regular price', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(
            record: OfferImportRecord(
              sourceId: 'invalid-regular-price',
              productLabel: 'Butter 250 g',
              storeName: 'Lidl',
              originalPrice: 1.49,
              offerPrice: 1.79,
              validUntil: DateTime(2026, 10, 2),
              proofRef: 'https://example.test/lidl/invalid-regular-price',
            ),
          ),
        ),
      ),
    );

    expect(find.text('1,79 €'), findsOneWidget);
    expect(find.text('1,49 €'), findsNothing);
    expect(find.textContaining('-%'), findsNothing);
  });

  testWidgets('shows a readable official source label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(
            record: OfferImportRecord(
              sourceId: 'official-source',
              productLabel: 'Milch 1 l',
              storeName: 'Lidl',
              offerPrice: 0.99,
              sourceAdapter: 'structured_api',
              validUntil: DateTime(2026, 10, 2),
              proofRef: 'https://example.test/lidl/official-source',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Quelle Offizielle Händlerquelle'), findsOneWidget);
    expect(find.text('Quelle structured_api'), findsNothing);
  });

  testWidgets('shows KaufDA capture time and prospect page when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectOfferCard(
            record: OfferImportRecord(
              sourceId: 'kaufda-page',
              productLabel: 'Butter 250 g',
              storeName: 'Lidl',
              offerPrice: 1.49,
              validUntil: DateTime(2026, 10, 2),
              source: 'retailerWebsite',
              sourceAdapter: 'kaufda',
              capturedAt: DateTime(2026, 9, 30, 8, 5),
              brochurePage: 3,
              proofRef: 'https://example.test/kaufda/butter',
            ),
            compact: true,
          ),
        ),
      ),
    );

    expect(find.text('Erfasst 30.09.2026 08:05 Uhr'), findsOneWidget);
    expect(find.text('Prospektseite 3'), findsOneWidget);
  });
}

