import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/shopping_offer_badge.dart';
import 'package:sparzamapp/features/shopping_list/shopping_offer_hint.dart';
import 'package:sparzamapp/models/offer.dart';

void main() {
  testWidgets('Angebotshinweis ist antippbar', (tester) async {
    var tapped = false;
    final hint = ShoppingOfferHint(
      storeName: 'Lidl',
      unitPrice: 0.99,
      total: 0.99,
      savings: 0.30,
      offer: Offer(
        id: 'offer',
        productId: 'milch_35',
        storeName: 'Lidl',
        originalPrice: 1.29,
        offerPrice: 0.99,
        validUntil: DateTime(2026, 9, 25),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingOfferBadge(
            hint: hint,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('Lidl'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.textContaining('Lidl'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
