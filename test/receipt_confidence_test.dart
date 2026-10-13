import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_confidence_badge.dart';
import 'package:sparzamapp/features/receipt/receipt_ledger.dart';
import 'package:sparzamapp/features/receipt/receipt_observation_builder.dart';
import 'package:sparzamapp/features/receipt/receipt_price_review.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/receipt_confidence.dart';

void main() {
  test('maps receipt review state to four conservative levels', () {
    expect(
      receiptConfidenceFor(
        productId: 'catalog-milk',
        identityConfirmed: true,
        familyKey: 'milch',
      ),
      ReceiptConfidenceLevel.manuellBestaetigt,
    );
    expect(
      receiptConfidenceFor(
        productId: 'receipt_auto-milk',
        identityConfirmed: false,
        familyKey: 'milch',
      ),
      ReceiptConfidenceLevel.wahrscheinlich,
    );
    expect(
      receiptConfidenceFor(
        productId: null,
        identityConfirmed: false,
        familyKey: 'milch',
      ),
      ReceiptConfidenceLevel.belegt,
    );
    expect(
      receiptConfidenceFor(
        productId: null,
        identityConfirmed: false,
        familyKey: '',
      ),
      ReceiptConfidenceLevel.unsicher,
    );
  });

  test('saved receipt observations expose their confidence without migration', () {
    final draft = parseReceiptLedger('''
Kaufland
Preis EUR
Unbekannte Milch 1,29 B
Summe 1,29
Datum 23.07.26
''');
    final observation = buildReceiptObservations(
      draft: draft,
      review: reviewReceiptPrices(draft, const <Product>[]),
    ).single;

    expect(observation.confidence, ReceiptConfidenceLevel.belegt);
    expect(observation.toJson(), isNot(contains('confidence')));
  });

  testWidgets('confidence badges expose labels and explanations', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
            ReceiptConfidenceBadge(level: ReceiptConfidenceLevel.belegt),
            ReceiptConfidenceBadge(level: ReceiptConfidenceLevel.wahrscheinlich),
            ReceiptConfidenceBadge(level: ReceiptConfidenceLevel.unsicher),
            ReceiptConfidenceBadge(
              level: ReceiptConfidenceLevel.manuellBestaetigt,
            ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('BELEGT'), findsOneWidget);
    expect(find.text('WAHRSCHEINLICH'), findsOneWidget);
    expect(find.text('UNSICHER'), findsOneWidget);
    expect(find.text('MANUELL-BESTÄTIGT'), findsNothing);
    expect(find.text('MANUELL_BESTÄTIGT'), findsOneWidget);
    expect(
      find.byTooltip(
        'Die konkrete Produktzuordnung wurde ausdrücklich bestätigt.',
      ),
      findsOneWidget,
    );
  });
}
