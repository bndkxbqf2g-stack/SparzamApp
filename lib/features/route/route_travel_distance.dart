import '../../models/road_route_matrix.dart';
import '../../models/store.dart';

class OptimizedTravelRoute {
  const OptimizedTravelRoute({
    required this.stores,
    required this.distanceKm,
    required this.usesRoadMatrix,
  });

  final List<Store> stores;
  final double distanceKm;
  final bool usesRoadMatrix;
}

OptimizedTravelRoute optimizeTravelRoute(
  Iterable<Store> selectedStores, {
  RoadRouteMatrix? roadMatrix,
  Map<String, double> fallbackDistances = const <String, double>{},
}) {
  final stores = selectedStores.toList();
  if (stores.isEmpty) {
    return const OptimizedTravelRoute(
      stores: [],
      distanceKm: 0,
      usesRoadMatrix: false,
    );
  }

  if (roadMatrix != null &&
      roadMatrix.covers(stores.map((store) => store.name))) {
    List<Store>? bestOrder;
    var bestDistance = double.infinity;

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

      if (distance < bestDistance) {
        bestDistance = distance;
        bestOrder = order;
      }
    }

    return OptimizedTravelRoute(
      stores: bestOrder!,
      distanceKm: bestDistance,
      usesRoadMatrix: true,
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
