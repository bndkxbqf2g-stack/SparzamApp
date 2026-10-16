import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/route_distance_persistence.dart';
import 'package:sparzamapp/models/road_route_matrix.dart';

void main() {
  test('continues with the distance cache when matrix persistence fails', () async {
    final events = <String>[];
    final matrix = RoadRouteMatrix(
      originAddress: 'Thüngersheim',
      distancesKm: const {'@origin|Lidl': 4.2},
    );

    await persistRouteDistanceCachesBestEffort(
      matrix: matrix,
      originAddress: 'Thüngersheim',
      distances: const {'Lidl': 4.2},
      saveMatrix: (_) async {
        events.add('matrix');
        throw StateError('preferences unavailable');
      },
      saveDistances: (origin, distances) async {
        events.add('distances:' + origin + ':' + distances['Lidl'].toString());
      },
    );

    expect(events, ['matrix', 'distances:Thüngersheim:4.2']);
  });

  test('swallows a distance cache failure after a successful matrix write', () async {
    final events = <String>[];
    final matrix = RoadRouteMatrix(
      originAddress: 'Würzburg',
      distancesKm: const {'@origin|Kaufland': 7.1},
    );

    await persistRouteDistanceCachesBestEffort(
      matrix: matrix,
      originAddress: 'Würzburg',
      distances: const {'Kaufland': 7.1},
      saveMatrix: (_) async => events.add('matrix'),
      saveDistances: (_, __) async {
        events.add('distances');
        throw StateError('quota exceeded');
      },
    );

    expect(events, ['matrix', 'distances']);
  });
}
