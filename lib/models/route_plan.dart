import 'list_item.dart';
import 'store.dart';

class RoutePlan {
  const RoutePlan({
    required this.stores,
    required this.assignments,
    required this.basket,
    required this.travel,
    required this.total,
    required this.unassigned,
    this.uncertaintyReserve = 0,
    this.travelMinutes = 0,
    this.timeCost = 0,
  });

  final List<Store> stores;
  final Map<Store, List<ListItem>> assignments;
  final double basket;
  final double travel;
  final double total;
  final List<ListItem> unassigned;

  /// Heuristic planning margin; it is not part of the amount paid.
  final double uncertaintyReserve;

  /// Estimated round-trip time in minutes. This is informational unless the
  /// user has configured a personal time value.
  final int travelMinutes;

  /// Personal time value used only for comparing routes; it is not charged.
  final double timeCost;
  double get planningScore => total + uncertaintyReserve + timeCost;

  int get pricedItemCount =>
      assignments.values.fold<int>(0, (sum, entries) => sum + entries.length);
  int get missingItemCount => unassigned.length;
  int get totalItemCount => pricedItemCount + missingItemCount;
  double get priceCoverage =>
      totalItemCount == 0 ? 0 : pricedItemCount / totalItemCount;
  bool get hasDataGaps => unassigned.isNotEmpty;
}
