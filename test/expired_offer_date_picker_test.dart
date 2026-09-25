import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_editor_screen.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  for (final daysFromToday in [-20, 500]) {
    testWidgets('Datumsauswahl für bestehenden Termin $daysFromToday Tage',
        (tester) async {
      final offer = Offer(
        id: 'old',
        productId: 'milk',
        storeName: 'Lidl',
        originalPrice: 2,
        offerPrice: 1,
        validUntil: DateTime.now().add(Duration(days: daysFromToday)),
      );
      await tester.pumpWidget(MaterialApp(
        home: OfferEditorScreen(
          offer: offer,
          catalogProducts: const [
            Product(id: 'milk', name: 'Milch', unit: 'Artikel', group: 'Milch'),
          ],
        ),
      ));

      await tester.tap(find.text('Gültig bis'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
