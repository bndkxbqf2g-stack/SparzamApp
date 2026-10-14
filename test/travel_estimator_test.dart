import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/travel_estimator.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
import 'package:sparzamapp/models/road_route_matrix.dart';
import 'package:sparzamapp/models/store.dart';

void main() {
  const store = Store(
    name: 'Markt',
    location: 'Ort',
    distanceKm: 9,
    prices: {},
  );

  test('Auto und Fahrrad verwenden dieselbe Strecke aber andere Zeit', () {
    final car = estimateRoundTrips(
      [store],
      mobility: const MobilitySettings(mode: MobilityMode.car),
      roadDistances: const {'Markt': 9},
    );
    final bike = estimateRoundTrips(
      [store],
      mobility: const MobilitySettings(mode: MobilityMode.bike),
      roadDistances: const {'Markt': 9},
    );

    expect(car.distanceKm, 18);
    expect(car.minutes, 24);
    expect(bike.minutes, 60);
  });

  test('OSRM-Rundtourdauer hat Vorrang vor der Mobilitätsheuristik', () {
    final estimate = estimateRoundTrips(
      [store],
      mobility: const MobilitySettings(mode: MobilityMode.car),
      roadMatrix: const RoadRouteMatrix(
        originAddress: 'Start',
        distancesKm: {
          '@origin|Markt': 9,
          'Markt|@origin': 9,
        },
        durationsMinutes: {
          '@origin|Markt': 17,
          'Markt|@origin': 19,
        },
      ),
    );

    expect(estimate.distanceKm, 18);
    expect(estimate.minutes, 36);
  });

  test('Fußweg wird lesbar als Stunden und Minuten formatiert', () {
    final walk = estimateRoundTrips(
      [store],
      mobility: const MobilitySettings(mode: MobilityMode.walk),
    );

    expect(walk.minutes, 216);
    expect(walk.durationLabel, '3 Std. 36 Min.');
  });
}
