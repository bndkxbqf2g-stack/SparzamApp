import '../models/road_route_matrix.dart';

/// Local cache boundary for route matrices.
///
/// Implementations must keep cached matrices local and may return null when a
/// value is missing or too old. A cache failure is never a routing result.
abstract interface class TravelMatrixCache {
  Future<RoadRouteMatrix?> load(
    String originAddress, {
    DateTime? now,
    Duration maxAge = const Duration(hours: 24),
  });

  Future<void> save(RoadRouteMatrix matrix);
}
