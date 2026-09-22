import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/services/road_distance_service.dart';

void main() {
  test('Straßenentfernung wird aus Routing-Antwort berechnet', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'nominatim.openstreetmap.org') {
        final query = request.url.queryParameters['q'] ?? '';
        if (query.contains('Zellingen')) {
          return http.Response(
            '[{"lat":"49.8978","lon":"9.8172"}]',
            200,
          );
        }
        return http.Response(
          '[{"lat":"49.9100","lon":"9.8500"}]',
          200,
        );
      }

      if (request.url.host == 'router.project-osrm.org') {
        return http.Response(
          '{"routes":[{"distance":4200.0}],"code":"Ok"}',
          200,
        );
      }

      return http.Response('', 404);
    });

    final service = RoadDistanceService(client: client);
    final distance = await service.fetchKm('Testmarkt, Germany');

    expect(distance, 4.2);
    service.close();
  });

  test('fehlgeschlagene Routenantwort liefert null', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'nominatim.openstreetmap.org') {
        return http.Response(
          '[{"lat":"49.8978","lon":"9.8172"}]',
          200,
        );
      }
      return http.Response('', 500);
    });

    final service = RoadDistanceService(client: client);
    final distance = await service.fetchKm('Testmarkt, Germany');

    expect(distance, isNull);
    service.close();
  });
}
