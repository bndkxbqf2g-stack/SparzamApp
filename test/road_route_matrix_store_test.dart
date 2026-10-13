import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  test('Matrixcache verwendet die normalisierte Startadresse', () async {
    final store = RoadRouteMatrixStore();
    final now = DateTime(2026, 9, 22, 12);
    await store.save(
      RoadRouteMatrix(
        originAddress: '  Thüngersheim  ',
        distancesKm: const {'@origin|Lidl': 4, 'Lidl|@origin': 4},
        fetchedAt: now.subtract(const Duration(hours: 1)),
      ),
    );

    expect(await store.load('thüngersheim', now: now), isNotNull);
  });

  test('Matrizen mehrerer Startorte überschreiben sich nicht', () async {
    final store = RoadRouteMatrixStore();
    final now = DateTime(2026, 9, 22, 12);
    final first = RoadRouteMatrix(
      originAddress: 'Start A',
      distancesKm: const {'@origin|Lidl': 2, 'Lidl|@origin': 2},
      fetchedAt: now.subtract(const Duration(hours: 1)),
    );
    final second = RoadRouteMatrix(
      originAddress: 'Start B',
      distancesKm: const {'@origin|Lidl': 7, 'Lidl|@origin': 7},
      fetchedAt: now.subtract(const Duration(hours: 1)),
    );

    await store.save(first);
    await store.save(second);

    expect(await store.load('Start A', now: now), isNotNull);
    expect(
      (await store.load('Start A', now: now))?.distance(
        RoadRouteMatrix.origin,
        'Lidl',
      ),
      2,
    );
    expect(
      (await store.load('Start B', now: now))?.distance(
        RoadRouteMatrix.origin,
        'Lidl',
      ),
      7,
    );
  });

  test('ein paralleler Matrix-Read wartet auf den Schreibvorgang', () async {
    final store = RoadRouteMatrixStore();
    final reader = RoadRouteMatrixStore();
    final now = DateTime(2026, 9, 22, 12);
    final matrix = RoadRouteMatrix(
      originAddress: 'Start A',
      distancesKm: const {'@origin|Lidl': 2, 'Lidl|@origin': 2},
      fetchedAt: now.subtract(const Duration(hours: 1)),
    );
    final writing = store.save(matrix);
    final reading = reader.load('Start A', now: now);

    await writing;
    expect(await reading, isNotNull);
  });

  test('liest eine alte Einzelmatrix weiter', () async {
    final now = DateTime(2026, 9, 22, 12);
    await SharedPreferencesAsync().setString(
      'road_route_matrix_v1',
      jsonEncode({
        'originAddress': 'Start A',
        'distancesKm': {'@origin|Lidl': 2, 'Lidl|@origin': 2},
        'fetchedAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
      }),
    );

    expect(await RoadRouteMatrixStore().load('Start A', now: now), isNotNull);
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
