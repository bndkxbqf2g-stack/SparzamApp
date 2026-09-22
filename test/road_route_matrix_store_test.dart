import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/models/road_route_matrix.dart';
import 'package:sparzamapp/services/road_route_matrix_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('Distanzmatrix wird nur für denselben Startort geladen', () async {
    final store = RoadRouteMatrixStore();
    final now = DateTime(2026, 9, 22, 12);
    final matrix = RoadRouteMatrix(
      originAddress: 'Start A',
      distancesKm: {
        '@origin|Lidl': 2,
        'Lidl|@origin': 2.1,
      },
      fetchedAt: now.subtract(const Duration(hours: 2)),
    );

    await store.save(matrix);

    expect(await store.load('Start A', now: now), isNotNull);
    expect(await store.load('Start B', now: now), isNull);
  });

  test('veraltete oder undatierte Matrizen werden neu geladen', () async {
    final store = RoadRouteMatrixStore();
    final now = DateTime(2026, 9, 22, 12);
    final stale = RoadRouteMatrix(
      originAddress: 'Start A',
      distancesKm: const {'@origin|Lidl': 2},
      fetchedAt: now.subtract(const Duration(hours: 25)),
    );

    await store.save(stale);
    expect(await store.load('Start A', now: now), isNull);

    const legacy = RoadRouteMatrix(
      originAddress: 'Start A',
      distancesKm: {'@origin|Lidl': 2},
    );
    await store.save(legacy);
    expect(await store.load('Start A', now: now), isNull);
  });
}
