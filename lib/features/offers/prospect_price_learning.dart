import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../services/quantity_normalizer.dart';
import '../../services/barcode_normalizer.dart';
import '../catalog/product_identity.dart';
import 'offer_import.dart';
import 'prospect_product_match.dart';
import '../prospects/prospect_issue_identity.dart';
import '../../services/prospect_feed_service.dart';

/// Learns prospect prices only when an observation time is supplied.
///
/// A feed timestamp is preferred, but a record-level [OfferImportRecord.capturedAt]
/// is equally valid evidence. A record without either timestamp remains visible
/// but is not learned; the app never substitutes the local load time.
List<PriceObservation> datedProspectPriceObservations({
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  DateTime? observedAt,
  Iterable<String>? refreshedStores,
  Iterable<ProspectRefreshScope>? refreshedStoreScopes,
}) {
  // Prefer the branch-aware scope when the feed provides it. The legacy
  // retailer-label list remains a compatibility fallback for callers and
  // older fixtures that cannot express branch status.
  final scopes = refreshedStoreScopes?.toList(growable: false);
  final eligibleRecords = scopes != null && scopes.isNotEmpty
      ? records.where(
          (record) => scopes.any(
            (scope) => scope.matches(
              candidateStoreName: record.storeName,
              candidateBranchId: record.branchId,
            ),
          ),
        )
      : _recordsInLegacyRefreshScope(
          records,
          refreshedStores,
        );
  return prospectPriceObservations(
    records: eligibleRecords,
    catalogProducts: catalogProducts,
    observedAt: observedAt,
  );
}

/// Selects only explicitly stated regular prices for automatic persistence.
///
/// The feed's offer price remains the current offer surface and is already
/// persisted through the offer store. Automatic price history must keep the
/// crossed-out/regular amount separate and must never turn an offer-only
/// record into a regular market price.
List<PriceObservation> datedProspectRegularPriceObservations({
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  DateTime? observedAt,
  Iterable<String>? refreshedStores,
  Iterable<ProspectRefreshScope>? refreshedStoreScopes,
}) => datedProspectPriceObservations(
      records: records,
      catalogProducts: catalogProducts,
      observedAt: observedAt,
      refreshedStores: refreshedStores,
      refreshedStoreScopes: refreshedStoreScopes,
    )
    .where((entry) => entry.kind == PriceObservationKind.regular)
    .toList(growable: false);

/// Turns a verified prospect claim into dated price evidence. An unknown or
/// package-ambiguous label remains historical evidence, not an exact route
/// price. Both the temporary offer price and a stated regular price are kept.
/// Returns only regular-price evidence from prospect records that are
/// active on the selected day. Feed refreshes may retain historical and
/// future periods for diagnostics, but automatic current-price persistence
/// must never promote either period into the current database snapshot.
List<PriceObservation> currentDatedProspectRegularPriceObservations({
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  DateTime? observedAt,
  DateTime? now,
  Iterable<String>? refreshedStores,
  Iterable<ProspectRefreshScope>? refreshedStoreScopes,
}) {
  final reference = now ?? DateTime.now();
  final current = datedProspectRegularPriceObservations(
    records: currentProspectRecords(records, now: reference),
    catalogProducts: catalogProducts,
    observedAt: observedAt,
    refreshedStores: refreshedStores,
    refreshedStoreScopes: refreshedStoreScopes,
  );
  // A source can attach an individual capture time that is newer than the
  // feed timestamp. A future capture is provenance-invalid and must not be
  // promoted into the automatic local regular-price basis.
  return current
      .where(
        (entry) =>
            entry.isValid &&
            !entry.observedAt.isAfter(reference) &&
            (entry.validFrom == null ||
                !entry.validFrom!.isAfter(reference)),
      )
      .toList(growable: false);
}

/// Shared feed boundary for automatic prospect price evidence.
///
/// The coverage UI and the persistence path must agree on the same basic
/// provenance checks. Identity resolution is intentionally evaluated later;
/// an unknown product may remain historical evidence, but malformed source
/// rows must never be counted as learnable in the first place.
bool isEligibleProspectPriceRecord(OfferImportRecord record) {
  final source = _source(record.source);
  return source != null &&
      record.sourceId.trim().isNotEmpty &&
      record.storeName.trim().isNotEmpty &&
      record.productLabel.trim().isNotEmpty &&
      !record.regionalOnly &&
      isFoodProspectRecord(
        label: record.productLabel,
        category: record.category,
      ) &&
      (record.ean?.trim().isNotEmpty != true ||
          normalizeBarcode(record.ean!.trim()) != null) &&
      hasExactOfferRecordBranch(record) &&
      hasTrustedOfferProofReference(record.proofRef) &&
      record.offerPrice.isFinite &&
      record.offerPrice > 0 &&
      (record.originalPrice == null ||
          (record.originalPrice!.isFinite &&
              record.originalPrice! >= record.offerPrice)) &&
      (record.originalPrice == null ||
          isKnownProspectRegularPriceSource(record.regularPriceSource)) &&
      (record.validFrom == null ||
          !record.validUntil.isBefore(record.validFrom!));
}

/// Returns true only for a crossed-out regular price that the persistence
/// pipeline can actually accept. Offer-only rows and malformed evidence stay
/// out of the regular-price count.
bool isLearnableProspectRegularPrice(OfferImportRecord record) {
  if (!isEligibleProspectPriceRecord(record)) return false;
  final regular = record.originalPrice;
  if (regular == null || !regular.isFinite || regular <= record.offerPrice) {
    return false;
  }
  // Fresh adapter feeds carry the exact normalized field that supplied the
  // crossed-out amount. A missing marker on a legacy, manually constructed
  // record remains readable, but it is not enough for automatic persistence
  // once a concrete adapter identity is present.
  final adapter = record.sourceAdapter?.trim();
  final source = record.regularPriceSource?.trim();
  if (adapter != null &&
      adapter.isNotEmpty &&
      (source == null || source.isEmpty)) {
    return false;
  }
  return source == null ||
      source.isEmpty ||
      canonicalProspectRegularPriceSource(source) != null;
}

List<PriceObservation> prospectPriceObservations({
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  DateTime? observedAt,
}) {
  final catalog = catalogProducts.toList(growable: false);
  final observations = <PriceObservation>[];
  for (final record in records) {
    final source = _source(record.source);
    if (source == null || !isEligibleProspectPriceRecord(record)) {
      continue;
    }
    final observationAt = record.capturedAt ?? observedAt;
    if (observationAt == null) continue;

    final normalizedLabel = normalizeIdentityText(record.productLabel);
    if (normalizedLabel.isEmpty) continue;
    final identity = identifyProduct(record.productLabel);
    final package = prospectPackage(record.packageSize ?? record.productLabel);
    // KaufDA may put the package basis in a separate field and use a generic
    // label such as `Kaffee`. Resolve that one narrow case through the normal
    // offer importer; unrelated labels such as `Melitta Kaffee 500 g` remain
    // historical fallback evidence unless their full catalog identity is
    // explicit.
    final exactProduct =
        (record.ean?.trim().isNotEmpty == true ||
            (record.packageSize != null && _isKaufdaEvidence(record)))
        ? resolveOfferImport(record, catalog).product
        : exactProspectProduct(
            record.productLabel,
            catalog,
            packageSize: record.packageSize,
          );
    final productId = exactProduct?.id ?? 'prospect|$normalizedLabel';
    final confidence = exactProduct == null ? 0.0 : 1.0;
    final prefix = [
      'prospect',
      source.name,
      record.storeName,
      record.sourceId,
      productId,
      record.validUntil.toIso8601String(),
    ].join('|');
    final unitPrice = package == null
        ? null
        : normalizedUnitPrice(
            price: record.offerPrice,
            amount: package.amount,
            unit: package.unit,
          );

    observations.add(
      PriceObservation(
        id: '$prefix|offer|${record.offerPrice.toStringAsFixed(4)}',
        productId: productId,
        familyKey: identity.familyKey,
        variant: identity.variantKey,
        ean: exactProduct?.ean ?? record.ean,
        storeName: record.storeName,
        price: record.offerPrice,
        quantity: package?.amount,
        unit: package?.unit,
        unitPrice: unitPrice,
        observedAt: observationAt,
        source: source,
        sourceAdapter: record.sourceAdapter,
        kind: PriceObservationKind.offer,
        validFrom: record.validFrom,
        validUntil: record.validUntil,
        locationId: record.branchId,
        region: record.location,
        proofRef: record.proofRef,
        discounted: true,
        identityConfidence: confidence,
      ),
    );

    final regular = record.originalPrice;
    // Only a strictly higher original amount is a crossed-out regular price.
    // Equal amounts are still valid offer evidence, but they must never be
    // promoted into automatic regular-price history.
    if (regular != null &&
        regular > record.offerPrice &&
        isLearnableProspectRegularPrice(record)) {
      observations.add(
        PriceObservation(
          id: '$prefix|regular|${regular.toStringAsFixed(4)}',
          productId: productId,
          familyKey: identity.familyKey,
          variant: identity.variantKey,
          ean: exactProduct?.ean ?? record.ean,
          storeName: record.storeName,
          price: regular,
          quantity: package?.amount,
          unit: package?.unit,
          unitPrice: package == null
              ? null
              : normalizedUnitPrice(
                  price: regular,
                  amount: package.amount,
                  unit: package.unit,
                ),
          observedAt: observationAt,
          source: source,
          sourceAdapter: record.sourceAdapter,
          regularPriceSource: canonicalProspectRegularPriceSource(
            record.regularPriceSource,
          ),
          kind: PriceObservationKind.regular,
          validFrom: record.validFrom,
          validUntil: record.validUntil,
          locationId: record.branchId,
          region: record.location,
          proofRef: record.proofRef,
          identityConfidence: confidence,
        ),
      );
    }
  }
  return observations;
}

PriceObservationSource? _source(String source) =>
    switch (canonicalProspectSourceToken(source)) {
      'leaflet' => PriceObservationSource.leaflet,
      'retailer' => PriceObservationSource.retailer,
      'retailerWebsite' => PriceObservationSource.retailerWebsite,
      _ => null,
    };

// Use the same presentation-only key as the prospect UI when the feed
// does not yet provide branch-aware scope. This keeps ALDI Süd and
// ALDI SUED in the same legacy refresh scope without changing stored
// retailer labels or branch IDs.
String _prospectStoreKey(String value) => prospectStoreMatchKey(value);

Iterable<OfferImportRecord> _recordsInLegacyRefreshScope(
  Iterable<OfferImportRecord> records,
  Iterable<String>? refreshedStores,
) {
  final refreshedStoreKeys = refreshedStores
      ?.map(_prospectStoreKey)
      .where((store) => store.isNotEmpty)
      .toSet();
  if (refreshedStoreKeys == null) return records;
  return records.where(
    (record) => refreshedStoreKeys.contains(
      _prospectStoreKey(record.storeName),
    ),
  );
}

bool _isKaufdaEvidence(OfferImportRecord record) {
  if (record.sourceAdapter?.trim().toLowerCase() == 'kaufda') return true;
  final proof = record.proofRef?.trim().toLowerCase() ?? '';
  return proof.contains('kaufda.de');
}

