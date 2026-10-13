import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_evidence.dart';
import 'package:sparzamapp/models/offer.dart';

void main() {
  testWidgets('does not build an image for an unsafe stored offer URL', (
    tester,
  ) async {
    final offer = Offer(
      id: 'offer-1',
      productId: 'milch',
      storeName: 'Lidl',
      originalPrice: 1.49,
      offerPrice: 0.99,
      validUntil: DateTime(2026, 10, 17),
      imageUrl: 'javascript:alert(1)',
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: OfferEvidence(offer: offer))),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.bySemanticsLabel('Prospektbild'), findsNothing);
  });
}
