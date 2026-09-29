import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/offers_screen.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const product = Product(
    id: 'milk',
    name: 'Milch',
    unit: 'Artikel',
    group: 'Milch',
  );

  testWidgets('Angebote zeigt nur aktuelle Prospektdaten', (tester) async {
    final storedOffer = Offer(
      id: 'stored',
      productId: product.id,
      storeName: 'Lidl',
      originalPrice: 2,
      offerPrice: 1,
      validUntil: DateTime(2026, 9, 30),
    );
    final records = [
      OfferImportRecord(
        sourceId: 'current',
        productLabel: 'Aktuelle Milch',
        storeName: 'REWE',
        originalPrice: 1.49,
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 28),
        validUntil: DateTime(2026, 10, 4),
      ),
      OfferImportRecord(
        sourceId: 'expired',
        productLabel: 'Alte Milch',
        storeName: 'REWE',
        originalPrice: 1.49,
        offerPrice: 0.79,
        validFrom: DateTime(2026, 9, 21),
        validUntil: DateTime(2026, 9, 27),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          offers: [storedOffer],
          catalogProducts: const [product],
          prospectRecords: records,
          now: DateTime(2026, 9, 29),
        ),
      ),
    );

    expect(find.text('Aktuelles Prospekt'), findsOneWidget);
    expect(find.text('Aktuelle Milch'), findsNothing);
    expect(find.text('Alte Milch'), findsNothing);
    expect(find.text('1 gespeicherte Angebote'), findsNothing);

    await tester.tap(find.text('REWE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milchprodukte'));
    await tester.pumpAndSettle();

    expect(find.text('Aktuelle Milch'), findsOneWidget);
    expect(find.text('Alte Milch'), findsNothing);
    expect(find.text('Lidl'), findsNothing);
  });
}
