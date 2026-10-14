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

  if (roadMatrix != null &&
      roadMatrix.covers(stores.map((store) => store.name))) {
    final durationMatrixComplete =
        roadMatrix.coversDurations(stores.map((store) => store.name));
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
        distance += roadMatrix.distance(previous, store.name)!;
        previous = store.name;
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
      final orderKey = order.map((store) => store.name).join('|');
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
        sum + (fallbackDistances[store.name] ?? store.distanceKm) * 2,
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
    final duration = matrix.durationMinutes(previous, store.name);
    if (duration == null || !duration.isFinite || duration < 0) return null;
    total += duration;
    previous = store.name;
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
