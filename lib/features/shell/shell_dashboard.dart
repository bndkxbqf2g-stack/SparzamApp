import '../../models/budget_plan.dart';
import '../../models/list_item.dart';
import '../../models/mobility_settings.dart';
import '../../models/offer.dart';
import '../../models/purchase_record.dart';
import '../../models/replenishment_suggestion.dart';
import '../../models/road_route_matrix.dart';
import '../budget/budget_calculator.dart';
import '../home/dashboard_data.dart';
import '../offers/offer_filter.dart';
import '../receipt/purchase_summary.dart';
import '../route/travel_estimator.dart';
import 'shell_routing.dart';

DashboardData buildShellDashboard({
  required List<ListItem> shoppingList,
  required List<Offer> offers,
  required MobilitySettings mobility,
  required Map<String, double> roadDistances,
  required RoadRouteMatrix? roadMatrix,
  required ShellRouting routing,
  required BudgetPlan budget,
  required List<PurchaseRecord> purchaseHistory,
  required List<ReplenishmentSuggestion> replenishment,
  DateTime? now,
}) {
  final best = routing.current?.bestPlan();
  final baseline = routing.regular?.bestSingleStorePlan();
  final savingsHasDataGaps = best != null &&
      baseline != null &&
      (best.hasDataGaps || baseline.hasDataGaps);
  final savings = best == null || baseline == null || savingsHasDataGaps
      ? 0.0
      : baseline.total - best.total;
  final travel = best == null
      ? const TravelEstimate(distanceKm: 0, minutes: 0)
      : estimateRoundTrips(
          best.stores,
          mobility: mobility,
          roadDistances: roadDistances,
          roadMatrix: mobility.mode == MobilityMode.car ? roadMatrix : null,
        );
  final planned = best == null || best.hasDataGaps ? 0.0 : best.basket;
  final snapshot = calculateBudget(budget, planned);
  final forecast = calculateBudgetForecast(budget, planned, now: now);
  final monthly = summarizeMonth(purchaseHistory, now: now);
  final current = now ?? DateTime.now();
  final day = DateTime(current.year, current.month, current.day);
  final activeOffers = offers
      .where(
        (offer) => isOfferDateRangeActive(
          validFrom: offer.validFrom,
          validUntil: offer.validUntil,
          now: day,
        ),
      )
      .length;

  return DashboardData(
    itemCount: shoppingList.length,
    activeOffers: activeOffers,
    routeNames: best == null
        ? 'Noch keine Route'
        : best.stores.map((store) => store.name).join(' + '),
    routeTotal: best?.total ?? 0,
    routeHasDataGaps: best?.hasDataGaps ?? false,
    routeCoverageLabel: best == null
        ? ''
        : '${best.pricedItemCount} von ${best.totalItemCount} Artikeln '
            'preislich belegt',
    savingsHasDataGaps: savingsHasDataGaps,
    routeTravelMinutes: travel.minutes,
    mobilityLabel: mobility.mode.label,
    todaySavings: savings > 0 ? savings : 0,
    monthlySavings: monthly.savings,
    monthlyPurchases: monthly.purchases,
    budgetRemaining: snapshot.afterPlannedShop,
    budgetConfigured: budget.isConfigured,
    replenishmentCount: replenishment.length,
    replenishmentPreview: replenishment.isEmpty
        ? ''
        : replenishment.take(3).map((item) => item.product.name).join(' · '),
    budgetProjectedSpend: forecast.projectedFoodSpend,
    budgetWeeklyAllowance: forecast.weeklyAllowance,
    budgetForecastLabel: switch (forecast.status) {
      BudgetForecastStatus.onTrack => 'im Plan',
      BudgetForecastStatus.warning => 'knapp',
      BudgetForecastStatus.overBudget => 'voraussichtlich drüber',
    },
  );
}
