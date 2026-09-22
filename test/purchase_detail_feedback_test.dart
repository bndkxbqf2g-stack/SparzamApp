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

  testWidgets('fehlgeschlagenes Löschen lässt erneuten Versuch zu',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: PurchaseDetailScreen(
        record: record,
        onSave: (_) async {},
        onDelete: (_) async {
          calls++;
          throw StateError('offline');
        },
      ),
    ));
    await tester.tap(find.byTooltip('Einkauf löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pump();
    await tester.pump();

    expect(calls, 1);
    expect(find.textContaining('konnte nicht gelöscht werden'), findsOneWidget);
    expect(tester.widget<IconButton>(
      find.byTooltip('Einkauf löschen'),
    ).onPressed, isNotNull);
  });

  testWidgets('ungültiger Warenkorb verändert die Kaufhistorie nicht',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: PurchaseDetailScreen(
        record: record,
        onSave: (_) async {
          calls++;
        },
        onDelete: (_) async {},
      ),
    ));
    await tester.enterText(find.byType(TextField).first, '-4');
    final button = find.text('Korrektur speichern');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(calls, 0);
    expect(find.textContaining('Bitte gültige, nicht negative Beträge'),
        findsOneWidget);
  });
}
