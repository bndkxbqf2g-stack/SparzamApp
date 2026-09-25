import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/receipt/receipt_screen.dart';
import 'package:sparzamapp/models/route_plan.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const store = Store(
    name: 'Lidl', location: 'Zellingen', distanceKm: 1, prices: {},
  );
  const plan = RoutePlan(
    stores: [store], assignments: {}, basket: 5, travel: 1,
    total: 6, unassigned: [],
  );

  Widget screen(Future<void> Function() onComplete) => MaterialApp(
        home: Scaffold(
          body: ReceiptScreen(
            plan: plan,
            baselineTotal: 8,
            history: const [],
            onComplete: onComplete,
            onUpdatePurchase: (_) async {},
            onDeletePurchase: (_) async {},
          ),
        ),
      );

  testWidgets('Doppeltippen startet nur einen Kaufabschluss', (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(screen(() {
      calls++;
      return pending.future;
    }));
    await tester.tap(find.text('Einkauf bestätigen'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    expect(find.text('Einkauf gespeichert.'), findsOneWidget);
  });

  testWidgets('Fehler ermöglicht erneuten Versuch', (tester) async {
    await tester.pumpWidget(screen(() async => throw StateError('failed')));
    await tester.tap(find.text('Einkauf bestätigen'));
    await tester.pump();

    expect(find.textContaining('konnte nicht gespeichert werden'),
        findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });
}
