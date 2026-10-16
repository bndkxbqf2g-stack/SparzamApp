import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/services/road_distance_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('Straßenentfernungen gelten nur für denselben Startort', () async {
    final store = RoadDistanceStore();
    const firstOrigin = 'Start A';
    const secondOrigin = 'Start B';

    await store.save(firstOrigin, const {'Lidl': 4.2});

    expect(await store.load(firstOrigin), const {'Lidl': 4.2});
    expect(await store.load(secondOrigin), isEmpty);
  });

  test('mehrere Startorte bleiben im Offline-Cache erhalten', () async {
    final store = RoadDistanceStore();

    await store.save('Start A', const {'Lidl': 4.2});
    await store.save('Start B', const {'Lidl': 7.1, 'Kaufland': 8.4});

    expect(await store.load('Start A'), const {'Lidl': 4.2});
    expect(
      await store.load('Start B'),
      const {'Lidl': 7.1, 'Kaufland': 8.4},
    );
  });

  test('Distanzcache verwendet die normalisierte Startadresse', () async {
    final store = RoadDistanceStore();
    await store.save('  Thüngersheim  ', const {'Lidl': 4});

    expect(await store.load('thüngersheim'), const {'Lidl': 4});
  });

  test('ein paralleler Lesevorgang wartet auf den Schreibvorgang', () async {
    final store = RoadDistanceStore();
    final reader = RoadDistanceStore();
    final writing = store.save('Start A', const {'Lidl': 4.2});
    final reading = reader.load('Start A');

    await writing;
    expect(await reading, const {'Lidl': 4.2});
  });

  test('behält gültige Werte aus einem teilweise beschädigten Cache', () async {
    await SharedPreferencesAsync().setString(
      'road_distances_v3',
      jsonEncode({
        'version': 1,
        'entries': {
          'start a': {
            'originAddress': 'Start A',
            'distances': {
              'Lidl': 4.2,
              'Kaufland': 'unbekannt',
              'Edeka': -1,
              'Penny': null,
            },
          },
        },
      }),
    );

    expect(await RoadDistanceStore().load('Start A'), const {'Lidl': 4.2});
  });

  test('liest den alten Einzel-Startort-Cache weiter', () async {
    await SharedPreferencesAsync().setString(
      'road_distances_v2',
      jsonEncode({
        'originAddress': 'Start A',
        'distances': {'Lidl': 4.2},
      }),
    );

    expect(await RoadDistanceStore().load('Start A'), const {'Lidl': 4.2});
  });
}
