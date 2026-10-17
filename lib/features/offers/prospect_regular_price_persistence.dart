import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../services/price_observation_store.dart';
import 'offer_import.dart';
import 'prospect_price_learning.dart';
import '../prospects/prospect_issue_identity.dart';
import '../../services/prospect_feed_service.dart';

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
  // A row may remain in the append-only local history after a successful
  // refresh supersedes it. Only the current projection is a confirmed
  // coverage result; matching an old ID alone would make the UI report a
  // price that route planning already excludes.
  final persistedIds = stored
      .where(
        (entry) =>
            entry.kind == PriceObservationKind.regular && entry.isCurrent,
      )
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
  Iterable<ProspectRefreshScope>? refreshedStoreScopes,
}) async {
  final learned = currentDatedProspectRegularPriceObservations(
    records: records,
    catalogProducts: catalogProducts,
    observedAt: observedAt,
    now: now,
    refreshedStores: refreshedStores,
    refreshedStoreScopes: refreshedStoreScopes,
  ).where((entry) => entry.locationId?.trim().isNotEmpty == true).toList(
        growable: false,
      );
  final refreshedStoreKeys = refreshedStores
      ?.map(_normalizedProspectStoreKey)
      .where((value) => value.isNotEmpty)
      .toSet();
  final refreshedScopes =
      refreshedStoreScopes?.toList(growable: false);
  // Reconcile by the stable product/branch slot, but keep the incoming
  // observation ID as the marker for the current value. A changed price or
  // validity period receives a new ID; the former observation must then become
  // historical even though its slot is still present in the refreshed feed.
  final currentIdsByKey = <String, Set<String>>{};
  for (final entry in learned) {
    currentIdsByKey
        .putIfAbsent(_prospectRegularCurrentKey(entry), () => <String>{})
        .add(entry.id);
  }
  final stored = await store.upsertById(
    learned,
    // Remove legacy automatic offer observations even when a cache lacks a
    // feed timestamp. They are never routeable prices and must not remain in
    // the local prospect price database.
    removeWhere: _isAutomaticProspectOfferObservation,
    // A successful refresh reconciles the current projection while retaining
    // superseded rows for historical inspection.
    rewriteExisting: (existing) {
      final hasRefreshScope =
          refreshedScopes != null && refreshedScopes.isNotEmpty ||
          refreshedStoreKeys != null && refreshedStoreKeys.isNotEmpty;
      if (!hasRefreshScope ||
          !_isCurrentProspectRegular(existing) ||
          !_isObservationInRefreshScope(
            existing,
            refreshedScopes: refreshedScopes,
            refreshedStoreKeys: refreshedStoreKeys,
          )) {
        return existing;
      }
      final currentIds =
          currentIdsByKey[_prospectRegularCurrentKey(existing)];
      if (currentIds != null && currentIds.contains(existing.id)) {
        return existing;
      }
      return _withProspectCurrent(existing, false);
    },
  );
  return ProspectRegularPricePersistenceResult(
    learned: learned,
    stored: stored,
  );
}

/// Identifies offer rows written by the legacy automatic prospect
/// projection. Older schemas did not always preserve [PriceObservation.kind],
/// but they did retain [discounted]; treat that marker as authoritative for
/// these namespaced IDs so an old discounted amount cannot become local price
/// evidence after the next refresh.
bool _isAutomaticProspectOfferObservation(PriceObservation observation) {
  final isLegacyProspectId =
      observation.id.startsWith('prospect|') ||
      observation.id.startsWith('offer|import|');
  return isLegacyProspectId &&
      (observation.kind == PriceObservationKind.offer || observation.discounted);
}
// Reconcile with the same presentation-only store key used by the feed and UI.
// The persisted display label and exact branch ID remain untouched.
String _normalizedProspectStoreKey(String value) => prospectStoreMatchKey(value);

bool _isObservationInRefreshScope(
  PriceObservation observation, {
  required Iterable<ProspectRefreshScope>? refreshedScopes,
  required Set<String>? refreshedStoreKeys,
}) {
  if (refreshedScopes != null && refreshedScopes.isNotEmpty) {
    return refreshedScopes.any(
      (scope) => scope.matches(
        candidateStoreName: observation.storeName,
        candidateBranchId: observation.locationId,
      ),
    );
  }
  if (refreshedStoreKeys == null || refreshedStoreKeys.isEmpty) return false;
  return refreshedStoreKeys.contains(
    _normalizedProspectStoreKey(observation.storeName),
  );
}

bool _isCurrentProspectRegular(PriceObservation entry) =>
    entry.isCurrent &&
    entry.kind == PriceObservationKind.regular &&
    switch (entry.source) {
      PriceObservationSource.retailer ||
      PriceObservationSource.retailerWebsite ||
      PriceObservationSource.leaflet => true,
      _ => false,
    };

String _prospectRegularCurrentKey(PriceObservation entry) => [
      entry.source.name,
      entry.sourceAdapter?.trim().toLowerCase() ?? '',
      _normalizedProspectStoreKey(entry.storeName),
      entry.locationId?.trim().toLowerCase() ?? '',
      entry.productId?.trim() ?? '',
      entry.familyKey?.trim().toLowerCase() ?? '',
      entry.variant?.trim().toLowerCase() ?? '',
      entry.quantity?.toStringAsFixed(6) ?? '',
      entry.unit?.trim().toLowerCase() ?? '',
    ].join('\u001f');

PriceObservation _withProspectCurrent(
  PriceObservation entry,
  bool isCurrent,
) => PriceObservation(
      id: entry.id,
      productId: entry.productId,
      familyKey: entry.familyKey,
      variant: entry.variant,
      ean: entry.ean,
      storeName: entry.storeName,
      locationId: entry.locationId,
      region: entry.region,
      price: entry.price,
      quantity: entry.quantity,
      unit: entry.unit,
      unitPrice: entry.unitPrice,
      kind: entry.kind,
      evidenceConfidence: entry.evidenceConfidence,
      validFrom: entry.validFrom,
      validUntil: entry.validUntil,
      observedAt: entry.observedAt,
      source: entry.source,
      sourceAdapter: entry.sourceAdapter,
      identityConfidence: entry.identityConfidence,
      proofRef: entry.proofRef,
      discounted: entry.discounted,
      isCurrent: isCurrent,
    );


/// Removes legacy automatic prospect offer evidence before the first feed
/// refresh. This keeps an offline/error launch from leaving offer prices in
/// the local prospect observation database; regular prices and user evidence
/// are preserved.
Future<List<PriceObservation>>
    purgeLegacyAutomaticProspectOfferObservations({
  required PriceObservationStore store,
}) => store.upsertById(
      const <PriceObservation>[],
      removeWhere: _isAutomaticProspectOfferObservation,
    );
