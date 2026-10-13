import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_details_screen.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  testWidgets('übernimmt ein geöffnetes Angebot in die Einkaufsliste', (
    tester,
  ) async {
    const product = Product(
      id: 'milk',
      name: 'Vollmilch',
      unit: '1 l',
      group: 'milch',
    );
    final offer = Offer(
      id: 'offer-milk',
      productId: product.id,
      storeName: 'Testmarkt',
      originalPrice: 1.39,
      offerPrice: 0.99,
      validUntil: DateTime(2026, 10, 17),
    );
    Product? added;

    await tester.pumpWidget(
      MaterialApp(
        home: OfferDetailsScreen(
          offer: offer,
          priceHistory: const [],
          items: const [],
          offers: const [],
          mobility: const MobilitySettings(),
          catalogProducts: const [product],
          marketPrices: const [],
          onAddToShoppingList: (value) => added = value,
        ),
      ),
    );

    expect(find.text('Zur Einkaufsliste'), findsOneWidget);
    await tester.tap(find.text('Zur Einkaufsliste'));
    expect(added, same(product));
  });
}
