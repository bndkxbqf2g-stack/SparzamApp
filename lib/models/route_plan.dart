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
  });

  final List<Store> stores;
  final Map<Store, List<ListItem>> assignments;
  final double basket;
  final double travel;
  final double total;
  final List<ListItem> unassigned;
  /// Heuristic planning margin; it is not part of the amount paid.
  final double uncertaintyReserve;
  double get planningScore => total + uncertaintyReserve;
}
