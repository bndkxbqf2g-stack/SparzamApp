import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_alternative_card.dart';
import 'package:sparzamapp/models/route_plan.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const store = Store(
    name: 'PENNY',
    location: 'Zellingen',
    distanceKm: 2,
    prices: {},
  );

  testWidgets('zeigt Wegezeit neben Kosten und Preisabdeckung', (tester) async {
    const plan = RoutePlan(
      stores: [store],
      assignments: {},
      basket: 4.50,
      travel: 0.96,
      total: 5.46,
      unassigned: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RouteAlternativeCard(plan: plan, travelLabel: '8 Min.'),
        ),
      ),
    );

    expect(find.textContaining('Wegezeit 8 Min.'), findsOneWidget);
    expect(find.textContaining('Fahrt 0.96 €'), findsOneWidget);
    expect(find.textContaining('Preisabdeckung 0 %'), findsOneWidget);
  });

  testWidgets('zeigt den persönlichen Zeitwert im Planungswert', (
    tester,
  ) async {
    const plan = RoutePlan(
      stores: [store],
      assignments: {},
      basket: 4.50,
      travel: 0.96,
      total: 5.46,
      unassigned: [],
      timeCost: 2.50,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RouteAlternativeCard(plan: plan, travelLabel: '8 Min.'),
        ),
      ),
    );

    expect(find.textContaining('Zeitwert 2.50 €'), findsOneWidget);
    expect(find.textContaining('Planungswert 7.96 €'), findsOneWidget);
  });
}
