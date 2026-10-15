import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../services/price_observation_store.dart';
import 'offer_import.dart';
import 'prospect_price_learning.dart';
import '../prospects/prospect_issue_identity.dart';

/// Counts the regular observations from the current feed that are
/// confirmed to exist in the local observation store.
///
/// The key includes an exact branch when one is present, so the coverage UI
/// cannot merge same-name retailers from different locations.
class ProspectRegularPricePersistenceSummary {
  const ProspectRegularPricePersistenceSummary({
    required this.count,
    required this.countsByBranch,
  });

  final int count;
  final Map<String, int> countsByBranch;
}

ProspectRegularPricePersistenceSummary
    summarizePersistedProspectRegularPrices({
  required Iterable<PriceObservation> learned,
  required Iterable<PriceObservation> stored,
}) {
  final persistedIds = stored
      .where((entry) => entry.kind == PriceObservationKind.regular)
      .map((entry) => entry.id)
      .toSet();
  final countsByBranch = <String, int>{};
  var count = 0;
  for (final entry in learned) {
    if (!persistedIds.contains(entry.id)) continue;
    count++;
    final key = prospectStoreBranchKey(
      storeName: entry.storeName,
      branchId: entry.locationId,
    );
    countsByBranch.update(
      key,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
  }
  return ProspectRegularPricePersistenceSummary(
    count: count,
    countsByBranch: Map.unmodifiable(countsByBranch),
  );
}

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
/// Only observations with an explicit exact branch are persisted; a source row
/// without one remains review/history evidence and cannot become a current route price.
/// The store upserts by the stable observation id, refreshing capture metadata
/// while keeping its existing compaction rules. A missing feed timestamp, an expired/future record, an
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
  ).where((entry) => entry.locationId?.trim().isNotEmpty == true).toList(
        growable: false,
      );
  final stored = await store.upsertById(
    learned,
    // Remove legacy automatic offer observations even when a cache lacks a
    // feed timestamp. They are never routeable prices and must not remain in
    // the local prospect price database.
    removeWhere: _isAutomaticProspectOfferObservation,
  );
  return ProspectRegularPricePersistenceResult(
    learned: learned,
    stored: stored,
  );
}

bool _isAutomaticProspectOfferObservation(PriceObservation observation) =>
    observation.kind == PriceObservationKind.offer &&
    observation.id.startsWith('prospect|');
