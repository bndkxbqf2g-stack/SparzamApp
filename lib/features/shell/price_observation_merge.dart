import '../../models/price_observation.dart';

/// Merges append-only observations from concurrent startup/refresh reads.
///
/// The persisted store serializes writes, but independent reads can complete
/// in either order. A later state update must therefore retain observations
/// already present in memory; a duplicate ID from the persisted read wins so
/// deterministic upserts can refresh its metadata.
List<PriceObservation> mergePriceObservations(
  Iterable<PriceObservation> current,
  Iterable<PriceObservation> loaded,
) {
  final byId = <String, PriceObservation>{
    for (final observation in current) observation.id: observation,
  };
  for (final observation in loaded) {
    byId[observation.id] = observation;
  }
  return byId.values.toList(growable: false);
}
