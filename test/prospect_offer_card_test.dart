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
    expect(find.text('Gültig bis 02.10.2026'), findsOneWidget);
    expect(find.text('-23 %'), findsOneWidget);

    await tester.tap(find.text('Zur Einkaufsliste'));
    await tester.pump();

    expect(added, isTrue);
    expect(find.text('Hinzugefügt'), findsOneWidget);
  });
}
