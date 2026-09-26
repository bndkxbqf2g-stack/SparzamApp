import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  testWidgets('shows market prospect cards instead of raw article summary',
      (tester) async {
    const prospects = [
      ProspectIssue(
        storeName: 'ALDI Süd',
        title: 'Aktionsprospekt',
        pages: [],
        url: 'https://example.test/aldi-prospekt',
      ),
      ProspectIssue(
        storeName: 'EDEKA',
        title: 'Aktionsprospekt',
        pages: [],
      ),
      ProspectIssue(
        storeName: 'Kaufland',
        title: 'Aktionsprospekt',
        pages: [],
      ),
      ProspectIssue(
        storeName: 'Lidl',
        title: 'Aktionsprospekt',
        pages: [],
      ),
      ProspectIssue(
        storeName: 'PENNY',
        title: 'Aktionsprospekt',
        pages: [],
      ),
      ProspectIssue(
        storeName: 'Netto',
        title: 'Aktionsprospekt',
        pages: [],
      ),
      ProspectIssue(
        storeName: 'REWE',
        title: 'Aktionsprospekt',
        pages: [],
      ),
    ];

    var added = false;
    final records = [
      OfferImportRecord(
        sourceId: 'aldi-berkkaese',
        productLabel: 'Kaiseralm Bergkäse',
        storeName: 'ALDI Süd',
        originalPrice: 2.99,
        offerPrice: 2.39,
        validFrom: DateTime(2026, 9, 21),
        validUntil: DateTime(2026, 9, 26),
        proofRef: 'https://example.test/aldi-berkkaese',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            records: records,
            prospects: prospects,
            onAddProduct: (_) => added = true,
          ),
        ),
      ),
    );

    expect(find.text('Prospekte'), findsOneWidget);
    expect(find.text('Alle Märkte'), findsOneWidget);
    expect(
      find.text('Aktuelle Prospekte. Produkte antippen und vormerken.'),
      findsOneWidget,
    );
    expect(find.text('1854 aktuelle Prospektartikel aus 5 Märkten'), findsNothing);

    await tester.tap(find.textContaining('ALDI Süd'));
    await tester.pumpAndSettle();

    expect(find.text('ALDI Süd'), findsWidgets);
    expect(
      find.textContaining('Aktuelle Angebote dieses Marktes'),
      findsOneWidget,
    );
    expect(find.textContaining('Offiziellen Prospekt öffnen'), findsOneWidget);
    expect(find.text('2,39 €'), findsOneWidget);
    expect(find.text('2,99 €'), findsOneWidget);

    await tester.tap(find.text('2,39 €'));
    await tester.pump();
    expect(added, isTrue);
  });
}
