import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/purchase_detail_screen.dart';
import 'package:sparzamapp/models/purchase_record.dart';

void main() {
  final record = PurchaseRecord(
    id: '1', createdAt: DateTime(2026, 9, 20),
    storeNames: const ['Lidl'], items: const [],
    basket: 5, travel: 1, total: 6, baselineTotal: 8,
  );

  testWidgets('fehlgeschlagene Korrektur bleibt bearbeitbar', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: PurchaseDetailScreen(
        record: record,
        onSave: (_) async {
          calls++;
          throw StateError('offline');
        },
        onDelete: (_) async {},
      ),
    ));
    final button = find.text('Korrektur speichern');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(calls, 1);
    expect(find.textContaining('konnte nicht gespeichert werden'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNotNull);
  });
}
