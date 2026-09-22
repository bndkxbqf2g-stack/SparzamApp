class DashboardData {
  const DashboardData({
    required this.itemCount,
    required this.activeOffers,
    required this.routeNames,
    required this.routeTotal,
    required this.routeTravelMinutes,
    required this.mobilityLabel,
    required this.todaySavings,
    required this.monthlySavings,
    required this.monthlyPurchases,
    required this.budgetRemaining,
    required this.budgetConfigured,
    required this.replenishmentCount,
    required this.replenishmentPreview,
  });

  final int itemCount;
  final int activeOffers;
  final String routeNames;
  final double routeTotal;
  final int routeTravelMinutes;
  final String mobilityLabel;
  final double todaySavings;
  final double monthlySavings;
  final int monthlyPurchases;
  final double budgetRemaining;
  final bool budgetConfigured;
  final int replenishmentCount;
  final String replenishmentPreview;
}
