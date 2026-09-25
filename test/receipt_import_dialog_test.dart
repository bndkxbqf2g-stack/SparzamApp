import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_import_dialog.dart';

void main() {
  testWidgets('receipt import uses clear Bonpreise action label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptImportDialog(
            products: const [],
            onSavePrices: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Bonpreise übernehmen'), findsOneWidget);
    expect(find.text('Ausgewählte Preise übernehmen'), findsNothing);
  });
}
