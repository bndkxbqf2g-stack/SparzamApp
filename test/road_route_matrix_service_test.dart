import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/models/road_route_matrix.dart';
import 'package:sparzamapp/services/road_distance_service.dart';

void main() {
  test('OSRM-Tabellenantwort wird als Distanzmatrix gespeichert', () async {
    var geocodeCount = 0;
    final client = MockClient((request) async {
      if (request.url.host == 'nominatim.openstreetmap.org') {
        geocodeCount++;
        final coordinate = switch (geocodeCount) {
          1 => ('49.90', '9.80'),
          2 => ('49.91', '9.81'),
          _ => ('49.92', '9.82'),
        };
        return http.Response(
          '[{"lat":"${coordinate.$1}","lon":"${coordinate.$2}"}]',
          200,
        );
      }

      if (request.url.host == 'router.project-osrm.org' &&
          request.url.path.startsWith('/table/v1/driving/')) {
        return http.Response(
          '''
          {
            "code": "Ok",
            "distances": [
              [0, 5000, 6000],
              [5100, 0, 1200],
              [6200, 1300, 0]
            ]
          }
          ''',
          200,
        );
      }

      return http.Response('', 404);
    });

    final service = RoadDistanceService(
      originAddress: 'Start',
      client: client,
      geocodeDelay: Duration.zero,
    );
    final matrix = await service.fetchMatrix({
      'A': 'Adresse A',
      'B': 'Adresse B',
    });

    expect(matrix, isNotNull);
    expect(matrix!.distance(RoadRouteMatrix.origin, 'A'), 5);
    expect(matrix.distance('A', 'B'), 1.2);
    expect(matrix.distance('B', RoadRouteMatrix.origin), 6.2);
    expect(matrix.covers(['A', 'B']), isTrue);

    service.close();
  });
}
