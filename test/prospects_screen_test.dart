import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';

void main() {
  testWidgets('shows raw prospect records and verified regular prices',
      (tester) async {
    final records = [
      OfferImportRecord(
        sourceId: 'aldi-gouda',
        productLabel: 'HOFBURGER Gouda jung 450 g',
        storeName: 'ALDI Süd',
        originalPrice: 3.79,
        offerPrice: 3.00,
        validFrom: DateTime.now().subtract(const Duration(days: 1)),
        validUntil: DateTime.now().add(const Duration(days: 3)),
        source: 'retailerWebsite',
        proofRef: 'https://example.test/aldi',
      ),
      OfferImportRecord(
        sourceId: 'edeka-sekt',
        productLabel: 'MM Extra Sekt',
        storeName: 'EDEKA',
        offerPrice: 2.77,
        validFrom: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 2)),
        source: 'retailerWebsite',
        proofRef: 'https://example.test/edeka',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ProspectsScreen(records: records))),
    );

    expect(find.text('2 aktuelle Prospektartikel aus 2 Märkten'), findsOneWidget);
    expect(find.text('ALDI Süd · 1'), findsOneWidget);
    expect(find.text('EDEKA · 1'), findsOneWidget);
    expect(find.text('HOFBURGER Gouda jung 450 g'), findsOneWidget);
    expect(find.text('MM Extra Sekt'), findsOneWidget);
    expect(find.text('Normalpreis 3.79 €'), findsOneWidget);
    expect(find.text('3.00 €'), findsOneWidget);
    expect(find.text('2.77 €'), findsOneWidget);
  });
}
