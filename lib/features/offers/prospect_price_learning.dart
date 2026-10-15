import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../services/quantity_normalizer.dart';
import '../../services/barcode_normalizer.dart';
import '../catalog/product_identity.dart';
import 'offer_import.dart';
import 'prospect_product_match.dart';

/// Learns prospect prices only when the feed supplies an observation time.
///
/// A missing feed timestamp is a provenance gap. Treating the load time as the
/// observation time would make an old or cached legacy feed look fresh in the
/// price history, so those records stay visible but are not learned.
List<PriceObservation> datedProspectPriceObservations({
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  DateTime? observedAt,
  Iterable<String>? refreshedStores,
}) {
  if (observedAt == null) return const <PriceObservation>[];
  // Feed adapters may differ only in whitespace or letter case. Normalize
  // that presentation detail while keeping distinct store names and aliases
  // separate; no fuzzy or cross-market matching is introduced here.
  final refreshedStoreKeys = refreshedStores
      ?.map(_prospectStoreKey)
      .where((store) => store.isNotEmpty)
      .toSet();
  final eligibleRecords = refreshedStoreKeys == null
      ? records
      : records.where(
          (record) => refreshedStoreKeys.contains(
            _prospectStoreKey(record.storeName),
          ),
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
}) => datedProspectPriceObservations(
      records: records,
      catalogProducts: catalogProducts,
      observedAt: observedAt,
      refreshedStores: refreshedStores,
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
}) =>
    datedProspectRegularPriceObservations(
      records: currentProspectRecords(records, now: now),
      catalogProducts: catalogProducts,
      observedAt: observedAt,
      refreshedStores: refreshedStores,
    );

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
      (record.ean?.trim().isNotEmpty != true ||
          normalizeBarcode(record.ean!.trim()) != null) &&
      hasExactOfferRecordBranch(record) &&
      hasTrustedOfferProofReference(record.proofRef) &&
      record.offerPrice.isFinite &&
      record.offerPrice > 0 &&
      (record.originalPrice == null ||
          (record.originalPrice!.isFinite &&
              record.originalPrice! >= record.offerPrice)) &&
      (record.validFrom == null ||
          !record.validUntil.isBefore(record.validFrom!));
}

/// Returns true only for a crossed-out regular price that the persistence
/// pipeline can actually accept. Offer-only rows and malformed evidence stay
/// out of the regular-price count.
bool isLearnableProspectRegularPrice(OfferImportRecord record) {
  if (!isEligibleProspectPriceRecord(record)) return false;
  final regular = record.originalPrice;
  return regular != null &&
      regular.isFinite &&
      regular > record.offerPrice;
}

List<PriceObservation> prospectPriceObservations({
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  required DateTime observedAt,
}) {
  final catalog = catalogProducts.toList(growable: false);
  final observations = <PriceObservation>[];
  for (final record in records) {
    final source = _source(record.source);
    if (source == null || !isEligibleProspectPriceRecord(record)) {
      continue;
    }

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
      record.source,
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
        observedAt: record.capturedAt ?? observedAt,
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
    if (regular != null && regular > record.offerPrice) {
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
          observedAt: record.capturedAt ?? observedAt,
          source: source,
          sourceAdapter: record.sourceAdapter,
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

PriceObservationSource? _source(String source) => switch (source) {
  'leaflet' => PriceObservationSource.leaflet,
  'retailer' => PriceObservationSource.retailer,
  'retailerWebsite' => PriceObservationSource.retailerWebsite,
  _ => null,
};

String _prospectStoreKey(String value) => value.trim().toLowerCase();

bool _isKaufdaEvidence(OfferImportRecord record) {
  if (record.sourceAdapter?.trim().toLowerCase() == 'kaufda') return true;
  final proof = record.proofRef?.trim().toLowerCase() ?? '';
  return proof.contains('kaufda.de');
}


