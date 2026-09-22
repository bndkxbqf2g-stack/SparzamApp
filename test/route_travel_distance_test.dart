import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_travel_distance.dart';
import 'package:sparzamapp/models/road_route_matrix.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const a = Store(
    name: 'A',
    location: 'Ort',
    distanceKm: 5,
    prices: {},
  );
  const b = Store(
    name: 'B',
    location: 'Ort',
    distanceKm: 6,
    prices: {},
  );
  const c = Store(
    name: 'C',
    location: 'Ort',
    distanceKm: 8,
    prices: {},
  );

  test('zwei Märkte werden als eine Rundtour statt Einzeltrips gerechnet', () {
    const matrix = RoadRouteMatrix(
      originAddress: 'Start',
      distancesKm: {
        '@origin|A': 5,
        'A|@origin': 5,
        '@origin|B': 6,
        'B|@origin': 6,
        'A|B': 1,
        'B|A': 1.5,
      },
    );

    final route = optimizeTravelRoute(
      [a, b],
      roadMatrix: matrix,
    );

    expect(route.usesRoadMatrix, isTrue);
    expect(route.distanceKm, 12);
    expect(route.stores.map((store) => store.name), ['A', 'B']);
  });

  test('bei drei Märkten wird die kürzeste Reihenfolge gewählt', () {
    const matrix = RoadRouteMatrix(
      originAddress: 'Start',
      distancesKm: {
        '@origin|A': 4,
        'A|@origin': 4,
        '@origin|B': 9,
        'B|@origin': 9,
        '@origin|C': 8,
        'C|@origin': 8,
        'A|B': 2,
        'B|A': 8,
        'A|C': 8,
        'C|A': 8,
        'B|C': 2,
        'C|B': 8,
      },
    );

    final route = optimizeTravelRoute(
      [c, a, b],
      roadMatrix: matrix,
    );

    expect(route.distanceKm, 16);
    expect(route.stores.map((store) => store.name), ['A', 'B', 'C']);
  });

  test('unvollständige Matrix fällt auf bisherige Distanzen zurück', () {
    const matrix = RoadRouteMatrix(
      originAddress: 'Start',
      distancesKm: {
        '@origin|A': 5,
        'A|@origin': 5,
      },
    );

    final route = optimizeTravelRoute(
      [a, b],
      roadMatrix: matrix,
      fallbackDistances: const {'A': 2, 'B': 3},
    );

    expect(route.usesRoadMatrix, isFalse);
    expect(route.distanceKm, 10);
  });
}
