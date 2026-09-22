import '../../models/mobility_settings.dart';
import '../../models/store.dart';

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
}) {
  final distance = stores.fold<double>(
    0,
    (sum, store) =>
        sum + (roadDistances[store.name] ?? store.distanceKm) * 2,
  );
  final minutes =
      ((distance / mobility.mode.averageSpeedKmh) * 60).round();

  return TravelEstimate(
    distanceKm: distance,
    minutes: minutes,
  );
}
