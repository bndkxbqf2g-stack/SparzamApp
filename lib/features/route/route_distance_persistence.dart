import '../../models/road_route_matrix.dart';

typedef RoadRouteMatrixWriter = Future<void> Function(RoadRouteMatrix matrix);
typedef RoadDistanceMapWriter = Future<void> Function(
  String originAddress,
  Map<String, double> distances,
);

/// Persists route distance evidence without making local storage part of the
/// live refresh success condition.
///
/// A fresh OSRM response remains useful in memory even when the device
/// preference store is unavailable, full, or corrupted. Each cache write is
/// attempted independently so a matrix write cannot prevent the legacy
/// distance map from being refreshed.
Future<void> persistRouteDistanceCachesBestEffort({
  required RoadRouteMatrix? matrix,
  required String originAddress,
  required Map<String, double> distances,
  required RoadRouteMatrixWriter saveMatrix,
  required RoadDistanceMapWriter saveDistances,
}) async {
  if (matrix != null) {
    try {
      await saveMatrix(matrix);
    } catch (_) {
      // Cache writes are an optimization; keep the live matrix.
    }
  }

  try {
    await saveDistances(originAddress, distances);
  } catch (_) {
    // Cache writes are an optimization; keep the live distance map.
  }
}
