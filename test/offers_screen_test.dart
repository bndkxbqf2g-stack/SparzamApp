import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/offers/offers_screen.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
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

    final addButton = find.byTooltip('Zur Einkaufsliste');
    expect(addButton, findsOneWidget);
    expect(tester.widget<IconButton>(addButton).onPressed, isNull);
  });
}
