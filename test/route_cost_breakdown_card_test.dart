import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/route/route_cost_breakdown_card.dart';
import 'package:sparzamapp/models/route_plan.dart';

void main() {
  testWidgets('zeigt Kassenkosten und Planungsaufschläge getrennt', (
    tester,
  ) async {
    final plan = RoutePlan(
      stores: const [],
      assignments: const {},
      basket: 12.34,
      travel: 1.20,
      total: 13.54,
      unassigned: const [],
      additionalStoreCost: 0.75,
      timeCost: 1.10,
      uncertaintyReserve: 0.40,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RouteCostBreakdownCard(plan: plan)),
      ),
    );

    expect(find.text('Kostenaufteilung'), findsOneWidget);
    expect(find.text('Warenkorb'), findsOneWidget);
    expect(find.text('12,34 €'), findsOneWidget);
    expect(find.text('Fahrt'), findsOneWidget);
    expect(find.text('1,20 €'), findsOneWidget);
    expect(find.text('Erwartete Gesamtkosten'), findsOneWidget);
    expect(find.text('13,54 €'), findsOneWidget);
    expect(find.text('Zusätzliche Marktstopps (Planung)'), findsOneWidget);
    expect(find.text('0,75 €'), findsOneWidget);
    expect(find.text('Zeitwert (Planung)'), findsOneWidget);
    expect(find.text('1,10 €'), findsOneWidget);
    expect(find.text('Preisunsicherheit (Vergleich)'), findsOneWidget);
    expect(find.text('0,40 €'), findsOneWidget);
    expect(find.text('Planungswert'), findsOneWidget);
    expect(find.text('15,79 €'), findsOneWidget);
    expect(
      find.textContaining('keine zusätzlichen Kassenkosten'),
      findsOneWidget,
    );
  });
}
