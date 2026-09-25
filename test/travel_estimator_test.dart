import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/route/travel_estimator.dart';
import 'package:sparzamapp/models/mobility_settings.dart';
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

  test('Fußweg wird lesbar als Stunden und Minuten formatiert', () {
    final walk = estimateRoundTrips(
      [store],
      mobility: const MobilitySettings(mode: MobilityMode.walk),
    );

    expect(walk.minutes, 216);
    expect(walk.durationLabel, '3 Std. 36 Min.');
  });
}
