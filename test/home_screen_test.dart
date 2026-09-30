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
  });
}
