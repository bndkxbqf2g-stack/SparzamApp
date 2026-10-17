import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_card.dart';
import 'package:sparzamapp/models/offer.dart';

void main() {
  testWidgets('zeigt die Angebots-Packungsbasis als Grundpreis', (tester) async {
    final offer = Offer(
      id: 'offer-unit-price',
      productId: 'coffee',
      storeName: 'Lidl',
      originalPrice: 3.49,
      offerPrice: 2.49,
      validUntil: DateTime(2026, 10, 17),
      packageAmount: 500,
      packageUnit: 'g',
      unitPrice: 4.98,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfferCard(
            offer: offer,
            priceHistory: const [],
            catalogProducts: const [],
          ),
        ),
      ),
    );

    expect(find.text('Grundpreis 4,98 €/kg'), findsOneWidget);
  });
  testWidgets('begrenzt Angebotsbilder für lange Scrolllisten', (tester) async {
    final offer = Offer(
      id: 'offer-scroll-image',
      productId: 'coffee',
      storeName: 'Lidl',
      originalPrice: 3.49,
      offerPrice: 2.49,
      validUntil: DateTime(2026, 10, 17),
      imageUrl: 'https://example.test/offer.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfferCard(
            offer: offer,
            priceHistory: const [],
            catalogProducts: const [],
          ),
        ),
      ),
    );

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(2));
    final resized = images.first.image as ResizeImage;
    expect(resized.width, 720);
    expect(resized.height, 360);
  });

}
