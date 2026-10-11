import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_summary_card.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/route_plan.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const store = Store(
    name: 'PENNY',
    location: 'Zellingen',
    distanceKm: 1,
    prices: {},
  );
  const missing = Product(
    id: 'missing',
    name: 'Zucchini',
    unit: 'Stück',
    group: 'gemuese',
  );

  testWidgets('verwendet die Singularform für eine offene Position', (
    tester,
  ) async {
    final plan = RoutePlan(
      stores: const [store],
      assignments: const {},
      basket: 0.99,
      travel: 0.48,
      total: 1.47,
      unassigned: [ListItem(product: missing)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RouteSummaryCard(best: plan, extraSavings: 0)),
      ),
    );

    expect(find.textContaining('1 Position.'), findsOneWidget);
    expect(find.textContaining('1 Positionen.'), findsNothing);
  });
}
