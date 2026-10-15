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
    this.additionalStoreCost = 0,
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

  /// Planning cost for every market after the first one. This is a user
  /// preference for effort/stop overhead, not a checkout amount.
  final double additionalStoreCost;

  double get planningScore =>
      total + uncertaintyReserve + timeCost + additionalStoreCost;

  int get pricedItemCount =>
      assignments.values.fold<int>(0, (sum, entries) => sum + entries.length);
  int get missingItemCount => unassigned.length;
  int get totalItemCount => pricedItemCount + missingItemCount;
  double get priceCoverage =>
      totalItemCount == 0 ? 0 : pricedItemCount / totalItemCount;
  bool get hasDataGaps => unassigned.isNotEmpty;
}

/// Stable identity for one exact store in a route comparison.
///
/// Visible retailer names are not unique: two branches can share the same
/// name while having different branch IDs, locations, or addresses. Keep all
/// available identity fields in the key so UI deduplication cannot collapse
/// distinct route stops.
String routeStoreIdentityKey(Store store) => [
      store.name,
      store.branchId ?? '',
      store.location,
      store.address,
    ].map((value) => value.trim().toLowerCase()).join('|');

/// Stable identity for a route alternative, including exact store branches
/// and the product assignments shown to the user.
String routePlanIdentityKey(RoutePlan plan) {
  final stores = plan.stores.map(routeStoreIdentityKey).toList()..sort();
  final assignments =
      plan.assignments.entries
          .expand(
            (entry) => entry.value.map(
              (item) =>
                  '${routeStoreIdentityKey(entry.key)}:${item.product.id}',
            ),
          )
          .toList()
        ..sort();
  return '${stores.join('|')}::${assignments.join('|')}';
}
