import '../../models/mobility_settings.dart';
import '../../models/road_route_matrix.dart';
import '../../models/store.dart';
import 'route_travel_distance.dart';

class TravelEstimate {
  const TravelEstimate({
    required this.distanceKm,
    required this.minutes,
  });

  final double distanceKm;
  final int minutes;

  String get durationLabel {
    if (minutes < 60) return '$minutes Min.';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours Std.' : '$hours Std. $rest Min.';
  }
}

TravelEstimate estimateRoundTrips(
  Iterable<Store> stores, {
  required MobilitySettings mobility,
  Map<String, double> roadDistances = const <String, double>{},
  RoadRouteMatrix? roadMatrix,
}) {
  final route = optimizeTravelRoute(
    stores,
    roadMatrix: roadMatrix,
    fallbackDistances: roadDistances,
  );
  final minutes =
      ((route.distanceKm / mobility.mode.averageSpeedKmh) * 60).round();

  return TravelEstimate(
    distanceKm: route.distanceKm,
    minutes: minutes,
  );
}
