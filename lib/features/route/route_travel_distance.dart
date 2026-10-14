import '../../models/road_route_matrix.dart';
import '../../models/store.dart';

class OptimizedTravelRoute {
  const OptimizedTravelRoute({
    required this.stores,
    required this.distanceKm,
    required this.usesRoadMatrix,
    this.durationMinutes,
  });

  final List<Store> stores;
  final double distanceKm;
  final bool usesRoadMatrix;

  /// OSRM travel time for the chosen round trip, when the source returned a
  /// complete duration matrix. Null keeps the configured speed fallback.
  final double? durationMinutes;
}

OptimizedTravelRoute optimizeTravelRoute(
  Iterable<Store> selectedStores, {
  RoadRouteMatrix? roadMatrix,
  Map<String, double> fallbackDistances = const <String, double>{},
  double euroPerKm = 0.22,
  double timeValuePerHour = 0,
}) {
  final stores = selectedStores.toList();
  if (stores.isEmpty) {
    return const OptimizedTravelRoute(
      stores: [],
      distanceKm: 0,
      usesRoadMatrix: false,
      durationMinutes: 0,
    );
  }

  final matrixKeys = roadMatrix == null
      ? const <String>[]
      : stores.map((store) => _matrixStoreKey(roadMatrix, store)).toList();
  if (roadMatrix != null && roadMatrix.covers(matrixKeys)) {
    final durationMatrixComplete = roadMatrix.coversDurations(matrixKeys);
    final fuelCostPerKm =
        euroPerKm.isFinite && euroPerKm >= 0 ? euroPerKm : 0;
    final timeValue =
        timeValuePerHour.isFinite && timeValuePerHour >= 0
            ? timeValuePerHour
            : 0;
    List<Store>? bestOrder;
    var bestDistance = double.infinity;
    var bestScore = double.infinity;
    var bestOrderKey = '';
    double? bestDuration;

    for (final order in _permutations(stores)) {
      var distance = 0.0;
      var previous = RoadRouteMatrix.origin;
      for (final store in order) {
        final key = _matrixStoreKey(roadMatrix, store);
        distance += roadMatrix.distance(previous, key)!;
        previous = key;
      }
      distance += roadMatrix.distance(
        previous,
        RoadRouteMatrix.origin,
      )!;

      final duration = durationMatrixComplete
          ? _durationForOrder(roadMatrix, order)
          : null;
      final score = duration == null
          ? distance
          : distance * fuelCostPerKm + duration / 60 * timeValue;
      final orderKey = order.map(_travelStoreTieKey).join('|');
      final candidateDuration = duration ?? double.infinity;
      final previousDuration = bestDuration ?? double.infinity;
      final isBetter = score < bestScore ||
          (score == bestScore &&
              (distance < bestDistance ||
                  (distance == bestDistance &&
                      (candidateDuration < previousDuration ||
                          (candidateDuration == previousDuration &&
                              (bestOrderKey.isEmpty ||
                                  orderKey.compareTo(bestOrderKey) < 0))))));
      if (isBetter) {
        bestScore = score;
        bestDistance = distance;
        bestOrder = order;
        bestDuration = duration;
        bestOrderKey = orderKey;
      }
    }

    return OptimizedTravelRoute(
      stores: bestOrder!,
      distanceKm: bestDistance,
      usesRoadMatrix: true,
      durationMinutes: bestDuration,
    );
  }

  final distance = stores.fold<double>(
    0,
    (sum, store) =>
        sum +
        (fallbackDistances[travelMatrixStoreKey(store)] ??
                fallbackDistances[store.name] ??
                store.distanceKm) *
            2,
  );

  return OptimizedTravelRoute(
    stores: stores,
    distanceKm: distance,
    usesRoadMatrix: false,
  );
}

Iterable<List<T>> _permutations<T>(List<T> items) sync* {
  if (items.length <= 1) {
    yield [...items];
    return;
  }

  for (var index = 0; index < items.length; index++) {
    final first = items[index];
    final rest = [...items]..removeAt(index);
    for (final tail in _permutations(rest)) {
      yield [first, ...tail];
    }
  }
}


double? _durationForOrder(RoadRouteMatrix matrix, List<Store> order) {
  var total = 0.0;
  var previous = RoadRouteMatrix.origin;
  for (final store in order) {
    final key = _matrixStoreKey(matrix, store);
    final duration = matrix.durationMinutes(previous, key);
    if (duration == null || !duration.isFinite || duration < 0) return null;
    total += duration;
    previous = key;
  }
  final returnDuration = matrix.durationMinutes(
    previous,
    RoadRouteMatrix.origin,
  );
  if (returnDuration == null ||
      !returnDuration.isFinite ||
      returnDuration < 0) {
    return null;
  }
  return total + returnDuration;
}

/// Stable key for new routing matrices. Legacy matrices can still use the
/// visible store name when no branch-specific node is present.
String travelMatrixStoreKey(Store store) {
  final branchId = store.branchId?.trim();
  if (branchId == null || branchId.isEmpty) return store.name;
  return '${store.name}#$branchId';
}

String _matrixStoreKey(RoadRouteMatrix matrix, Store store) {
  final branchKey = travelMatrixStoreKey(store);
  if (branchKey == store.name) return branchKey;
  final originPrefix = RoadRouteMatrix.origin + '|';
  final originSuffix = '|' + RoadRouteMatrix.origin;
  final hasBranchNode = matrix.distancesKm.keys.any(
        (key) => key == '$originPrefix$branchKey' || key == '$branchKey$originSuffix',
      ) ||
      matrix.durationsMinutes.keys.any(
        (key) => key == '$originPrefix$branchKey' || key == '$branchKey$originSuffix',
      );
  return hasBranchNode ? branchKey : store.name;
}

String _travelStoreTieKey(Store store) => [
  store.name,
  store.branchId ?? '',
  store.location,
  store.address,
].map((value) => value.trim().toLowerCase()).join('|');
