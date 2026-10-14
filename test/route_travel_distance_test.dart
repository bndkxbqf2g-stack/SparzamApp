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
      durationsMinutes: {
        '@origin|A': 12,
        'A|@origin': 13,
        '@origin|B': 20,
        'B|@origin': 14,
        'A|B': 3,
        'B|A': 4,
      },
    );

    final route = optimizeTravelRoute(
      [a, b],
      roadMatrix: matrix,
    );

    expect(route.usesRoadMatrix, isTrue);
    expect(route.distanceKm, 12);
    expect(route.durationMinutes, 29);
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

  test(
    'wählt bei vollständiger OSRM-Matrix die günstigere Zeit-/Fahrkostenroute',
    () {
      const matrix = RoadRouteMatrix(
        originAddress: 'Start',
        distancesKm: {
          '@origin|A': 1,
          'A|@origin': 1,
          '@origin|B': 4,
          'B|@origin': 4,
          'A|B': 1,
          'B|A': 3,
        },
        durationsMinutes: {
          '@origin|A': 40,
          'A|@origin': 5,
          '@origin|B': 5,
          'B|@origin': 5,
          'A|B': 5,
          'B|A': 5,
        },
      );

      final route = optimizeTravelRoute(
        [a, b],
        roadMatrix: matrix,
        euroPerKm: 0,
        timeValuePerHour: 60,
      );

      expect(route.stores.map((store) => store.name), ['B', 'A']);
      expect(route.distanceKm, 8);
      expect(route.durationMinutes, 15);
    },
  );

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
  test('branch-stabile Matrixschlüssel trennen gleichnamige Filialen', () {
    const branchA = Store(
      name: 'Lidl',
      branchId: 'lidl-a',
      location: 'Ort A',
      distanceKm: 1,
      prices: {},
    );
    const branchB = Store(
      name: 'Lidl',
      branchId: 'lidl-b',
      location: 'Ort B',
      distanceKm: 9,
      prices: {},
    );
    const matrix = RoadRouteMatrix(
      originAddress: 'Start',
      distancesKm: {
        '@origin|Lidl#lidl-a': 1,
        'Lidl#lidl-a|@origin': 1,
        '@origin|Lidl#lidl-b': 5,
        'Lidl#lidl-b|@origin': 5,
        'Lidl#lidl-a|Lidl#lidl-b': 2,
        'Lidl#lidl-b|Lidl#lidl-a': 3,
      },
      durationsMinutes: {
        '@origin|Lidl#lidl-a': 4,
        'Lidl#lidl-a|@origin': 4,
        '@origin|Lidl#lidl-b': 8,
        'Lidl#lidl-b|@origin': 8,
        'Lidl#lidl-a|Lidl#lidl-b': 5,
        'Lidl#lidl-b|Lidl#lidl-a': 6,
      },
    );

    final route = optimizeTravelRoute(
      [branchB, branchA],
      roadMatrix: matrix,
    );

    expect(route.usesRoadMatrix, isTrue);
    expect(route.distanceKm, 8);
    expect(route.durationMinutes, 13);
    expect(route.stores.map((store) => store.branchId), ['lidl-a', 'lidl-b']);
  });

}
