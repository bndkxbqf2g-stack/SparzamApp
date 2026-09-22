class DashboardData {
  const DashboardData({
    required this.itemCount,
    required this.activeOffers,
    required this.routeNames,
    required this.routeTotal,
    required this.todaySavings,
    required this.monthlySavings,
    required this.monthlyPurchases,
    required this.budgetRemaining,
    required this.budgetConfigured,
  });

  final int itemCount;
  final int activeOffers;
  final String routeNames;
  final double routeTotal;
  final double todaySavings;
  final double monthlySavings;
  final int monthlyPurchases;
  final double budgetRemaining;
  final bool budgetConfigured;
}
