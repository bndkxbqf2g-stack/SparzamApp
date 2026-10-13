import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_editor_screen.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  Future<void> openEditor(WidgetTester tester, ValueChanged<Offer> onSaved) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final offer = await Navigator.of(context).push<Offer>(
                MaterialPageRoute(
                  builder: (_) => const OfferEditorScreen(
                    catalogProducts: [
                      Product(id: 'milk', name: 'Milch', unit: 'Artikel', group: 'Milch'),
                    ],
                  ),
                ),
              );
              if (offer != null) onSaved(offer);
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Normalpreis €'), '2');
    await tester.enterText(find.widgetWithText(TextFormField, 'Angebot €'), '1');
  }

  Future<void> save(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Angebot speichern'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Angebot speichern'));
    await tester.pumpAndSettle();
  }

  testWidgets('ungültiger Coupon-Prozentwert blockiert Speichern', (tester) async {
    Offer? saved;
    await openEditor(tester, (offer) => saved = offer);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prozent %').first,
      '101',
    );
    await save(tester);
    expect(saved, isNull);
    expect(find.text('Prozent zwischen 0 und 100'), findsOneWidget);
  });

  testWidgets('Mehrfachkauf braucht beide Zahlen mit Bezahlen höchstens Kaufen',
      (tester) async {
    Offer? saved;
    await openEditor(tester, (offer) => saved = offer);
    await tester.enterText(find.widgetWithText(TextFormField, 'Kaufen'), '2');
    await save(tester);
    expect(saved, isNull);
    expect(find.text('Anzahl über 0 eingeben'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Bezahlen'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Bezahlen'), '3');
    await save(tester);
    expect(find.text('Nicht mehr bezahlen als kaufen'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Bezahlen'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Bezahlen'), '1');
    await save(tester);
    expect(saved?.buyQuantity, 2);
    expect(saved?.payQuantity, 1);
  });

  testWidgets('negative Cashback-Beträge werden abgelehnt', (tester) async {
    Offer? saved;
    await openEditor(tester, (offer) => saved = offer);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Betrag €').last,
      '-1',
    );
    await save(tester);
    expect(saved, isNull);
    expect(find.text('Gültigen Betrag eingeben'), findsOneWidget);
  });

  testWidgets('editing an imported offer keeps evidence for the same store', (
    tester,
  ) async {
    Offer? saved;
    final existing = Offer(
      id: 'kaufda-edit',
      productId: 'milk',
      storeName: 'Lidl',
      originalPrice: 2,
      offerPrice: 1,
      validUntil: DateTime(2026, 10, 17),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      capturedAt: DateTime(2026, 10, 12, 7),
      proofRef: 'https://www.kaufda.de/example',
      locationId: 'lidl_zellingen',
      region: 'Zellingen',
      address: 'Am Güßgraben 2, 97225 Zellingen',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<Offer>(
                  MaterialPageRoute(
                    builder: (_) => OfferEditorScreen(
                      offer: existing,
                      catalogProducts: const [
                        Product(
                          id: 'milk',
                          name: 'Milch',
                          unit: 'Artikel',
                          group: 'Milch',
                        ),
                      ],
                    ),
                  ),
                );
                saved = result;
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Angebot speichern'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Angebot speichern'));
    await tester.pumpAndSettle();

    expect(saved?.sourceAdapter, 'kaufda');
    expect(saved?.capturedAt, DateTime(2026, 10, 12, 7));
    expect(saved?.locationId, 'lidl_zellingen');
    expect(saved?.proofRef, 'https://www.kaufda.de/example');
  });

  testWidgets('editing an imported offer clears evidence after product change', (
    tester,
  ) async {
    Offer? saved;
    final existing = Offer(
      id: 'kaufda-product-change',
      productId: 'milk',
      storeName: 'Lidl',
      originalPrice: 2,
      offerPrice: 1,
      validUntil: DateTime(2026, 10, 17),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      capturedAt: DateTime(2026, 10, 12, 7),
      proofRef: 'https://www.kaufda.de/example',
      locationId: 'lidl_zellingen',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<Offer>(
                  MaterialPageRoute(
                    builder: (_) => OfferEditorScreen(
                      offer: existing,
                      catalogProducts: const [
                        Product(
                          id: 'milk',
                          name: 'Milch',
                          unit: 'Artikel',
                          group: 'Milch',
                        ),
                        Product(
                          id: 'yogurt',
                          name: 'Joghurt',
                          unit: 'Artikel',
                          group: 'Milchprodukte',
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milch').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joghurt').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Angebot speichern'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Angebot speichern'));
    await tester.pumpAndSettle();

    expect(saved?.productId, 'yogurt');
    expect(saved?.source, 'manual');
    expect(saved?.sourceAdapter, isNull);
    expect(saved?.capturedAt, isNull);
    expect(saved?.proofRef, isNull);
    expect(saved?.locationId, isNull);
  });
}
