import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/models/road_route_matrix.dart';
import 'package:sparzamapp/services/road_distance_service.dart';
import 'package:sparzamapp/services/travel_matrix_cache.dart';
import 'package:sparzamapp/services/travel_matrix_provider.dart';

class MemoryTravelMatrixCache implements TravelMatrixCache {
  MemoryTravelMatrixCache([this.matrix]);

  RoadRouteMatrix? matrix;
  var saves = 0;

  @override
  Future<RoadRouteMatrix?> load(
    String originAddress, {
    DateTime? now,
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final value = matrix;
    if (value == null || value.originAddress != originAddress) return null;
    return value.isFresh(now: now, maxAge: maxAge) ? value : null;
  }

  @override
  Future<void> save(RoadRouteMatrix matrix) async {
    saves++;
    this.matrix = matrix;
  }
}

void main() {
  final osrm = Uri.parse('https://osrm.test');
  final geocoder = Uri.parse('https://geocoder.test');

  test('OSRM provider is switchable and keeps the optimizer boundary explicit',
      () async {
    var requests = 0;
    final service = RoadDistanceService(
      originAddress: '97225 Zellingen, Germany',
      enabled: false,
      client: MockClient((_) async {
        requests++;
        return http.Response('', 500);
      }),
    );

    expect(service, isA<TravelMatrixProvider>());
    expect(service.enabled, isFalse);
    expect(await service.fetchKm('Testmarkt, Germany'), isNull);
    expect(
      await service.fetchMatrix({'Lidl': 'Testmarkt, Germany'}),
      isNull,
    );
    expect(requests, 0);
    service.close();
  });

  test('OSRM timeout returns an unknown distance', () async {
    final service = RoadDistanceService(
      originAddress: '97225 Zellingen, Germany',
      client: MockClient((request) async {
        if (request.url.host == 'geocoder.test') {
          return http.Response(
            '[{"lat":"49.8978","lon":"9.8172"}]',
            200,
          );
        }
        throw TimeoutException('OSRM timeout');
      }),
      osrmBaseUri: osrm,
      geocodingBaseUri: geocoder,
      geocodeDelay: Duration.zero,
      routeTimeout: const Duration(milliseconds: 1),
    );

    expect(await service.fetchKm('Testmarkt, Germany'), isNull);
    service.close();
  });

  test('live matrix is cached and can be reused offline', () async {
    final cache = MemoryTravelMatrixCache();
    final client = MockClient((request) async {
      if (request.url.host == 'geocoder.test') {
        return http.Response(
          '[{"lat":"49.8978","lon":"9.8172"}]',
          200,
        );
      }
      if (request.url.host == 'osrm.test') {
        expect(request.url.path, '/table/v1/driving/9.8172,49.8978;'
            '9.8172,49.8978');
        return http.Response(
          '{"distances":[[0,1000],[1000,0]],"code":"Ok"}',
          200,
        );
      }
      return http.Response('', 404);
    });

    final service = RoadDistanceService(
      originAddress: '97225 Zellingen, Germany',
      client: client,
      osrmBaseUri: osrm,
      geocodingBaseUri: geocoder,
      geocodeDelay: Duration.zero,
      matrixCache: cache,
    );
    final live = await service.fetchMatrix({'Lidl': 'Testmarkt, Germany'});

    expect(live?.distance(RoadRouteMatrix.origin, 'Lidl'), 1);
    expect(cache.saves, 1);

    service.close();
    final offline = RoadDistanceService(
      originAddress: '97225 Zellingen, Germany',
      client: MockClient((_) async {
        throw StateError('offline');
      }),
      osrmBaseUri: osrm,
      geocodingBaseUri: geocoder,
      geocodeDelay: Duration.zero,
      matrixCache: cache,
    );
    final cached = await offline.fetchMatrix({'Lidl': 'Testmarkt, Germany'});

    expect(cached?.distance(RoadRouteMatrix.origin, 'Lidl'), 1);
    offline.close();
  });
}
