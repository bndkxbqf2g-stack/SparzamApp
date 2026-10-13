import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/home/home_screen.dart';
import 'package:sparzamapp/features/home/dashboard_data.dart';

void main() {
  testWidgets('Dashboard kennzeichnet eine vorläufige Teilroute',
      (tester) async {
    const data = DashboardData(
      itemCount: 2,
      activeOffers: 0,
      routeNames: 'Lidl',
      routeTotal: 1.62,
      routeHasDataGaps: true,
      routeCoverageLabel: '1 von 2 Artikeln preislich belegt',
      savingsHasDataGaps: true,
      routeTravelMinutes: 4,
      mobilityLabel: 'Auto',
      todaySavings: 0,
      monthlySavings: 0,
      monthlyPurchases: 0,
      budgetRemaining: 50,
      budgetConfigured: true,
      replenishmentCount: 0,
      replenishmentPreview: '',
      budgetProjectedSpend: 0,
      budgetWeeklyAllowance: 0,
      budgetForecastLabel: 'im Plan',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          data: data,
          onOpenList: () {},
          onOpenRoute: () {},
          onOpenOffers: () {},
          onOpenBudget: () {},
          onOpenScanner: () {},
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('Teilroute prüfen'), findsOneWidget);
    expect(find.text('Preisabdeckung prüfen'), findsOneWidget);
    expect(find.textContaining('1 von 2 Artikeln preislich belegt'), findsOneWidget);
    expect(find.text('Planungsstatus'), findsOneWidget);
    expect(find.text('Lidl'), findsOneWidget);
    expect(find.text('Auto · 4 Min. Fahrtzeit'), findsOneWidget);
  });

  testWidgets('zeigt Monats- und Budgetprognose im Planungsstatus', (
    tester,
  ) async {
    const data = DashboardData(
      itemCount: 1,
      activeOffers: 3,
      routeNames: 'Lidl + Kaufland',
      routeTotal: 22.40,
      routeHasDataGaps: false,
      routeCoverageLabel: '1 von 1 Artikeln preislich belegt',
      savingsHasDataGaps: false,
      routeTravelMinutes: 18,
      mobilityLabel: 'Auto',
      todaySavings: 2.10,
      monthlySavings: 7.40,
      monthlyPurchases: 4,
      budgetRemaining: 48.60,
      budgetConfigured: true,
      replenishmentCount: 0,
      replenishmentPreview: '',
      budgetProjectedSpend: 112.00,
      budgetWeeklyAllowance: 34.50,
      budgetForecastLabel: 'knapp',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          data: data,
          onOpenList: () {},
          onOpenRoute: () {},
          onOpenOffers: () {},
          onOpenBudget: () {},
          onOpenScanner: () {},
        ),
      ),
    );

    expect(find.text('Diesen Monat gespart'), findsOneWidget);
    expect(find.text('7,40 €'), findsOneWidget);
    expect(find.text('4 bestätigte Einkäufe'), findsOneWidget);
    expect(find.text('Budgetprognose'), findsOneWidget);
    expect(find.text('knapp'), findsOneWidget);
    expect(find.text('Geplant 112,00 € · 34,50 €/Woche'), findsOneWidget);
  });
}