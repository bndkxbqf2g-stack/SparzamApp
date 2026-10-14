import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../services/price_observation_store.dart';
import 'offer_import.dart';
import 'prospect_price_learning.dart';

/// Result of one automatic prospect-price persistence pass.
///
/// [learned] contains only regular (crossed-out) prices from currently
/// active, dated prospect records. The offer amount is intentionally absent;
/// offers remain in the offer store and cannot become a regular route price.
class ProspectRegularPricePersistenceResult {
  const ProspectRegularPricePersistenceResult({
    required this.learned,
    required this.stored,
  });

  final List<PriceObservation> learned;
  final List<PriceObservation> stored;
}

/// Persists the current regular prospect prices and returns the complete local
/// observation snapshot.
///
/// The store deduplicates by the stable observation id and keeps its existing
/// compaction rules. A missing feed timestamp, an expired/future record, an
/// offer-only record, an unproven record, or a record without an exact branch
/// therefore cannot be promoted by this helper.
Future<ProspectRegularPricePersistenceResult>
    persistCurrentProspectRegularPrices({
  required PriceObservationStore store,
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  DateTime? observedAt,
  DateTime? now,
  Iterable<String>? refreshedStores,
}) async {
  final learned = currentDatedProspectRegularPriceObservations(
    records: records,
    catalogProducts: catalogProducts,
    observedAt: observedAt,
    now: now,
    refreshedStores: refreshedStores,
  );
  final stored = learned.isEmpty
      ? await store.load()
      : await store.append(learned);
  return ProspectRegularPricePersistenceResult(
    learned: learned,
    stored: stored,
  );
}
