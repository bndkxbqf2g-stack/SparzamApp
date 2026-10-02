import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../../services/quantity_normalizer.dart';
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
}) {
  if (observedAt == null) return const <PriceObservation>[];
  return prospectPriceObservations(
    records: records,
    catalogProducts: catalogProducts,
    observedAt: observedAt,
  );
}

/// Turns a verified prospect claim into dated price evidence. An unknown or
/// package-ambiguous label remains historical evidence, not an exact route
/// price. Both the temporary offer price and a stated regular price are kept.
List<PriceObservation> prospectPriceObservations({
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  required DateTime observedAt,
}) {
  final catalog = catalogProducts.toList(growable: false);
  final observations = <PriceObservation>[];
  for (final record in records) {
    final source = _source(record.source);
    if (source == null ||
        record.sourceId.trim().isEmpty ||
        record.storeName.trim().isEmpty ||
        record.productLabel.trim().isEmpty ||
        record.proofRef?.trim().isNotEmpty != true ||
        !record.offerPrice.isFinite ||
        record.offerPrice <= 0 ||
        (record.originalPrice != null &&
            (!record.originalPrice!.isFinite ||
                record.originalPrice! < record.offerPrice)) ||
        (record.validFrom != null &&
            record.validUntil.isBefore(record.validFrom!))) {
      continue;
    }

    final normalizedLabel = normalizeIdentityText(record.productLabel);
    if (normalizedLabel.isEmpty) continue;
    final identity = identifyProduct(record.productLabel);
    final package = prospectPackage(record.productLabel);
    final exactProduct = exactProspectProduct(record.productLabel, catalog);
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
        storeName: record.storeName,
        price: record.offerPrice,
        quantity: package?.amount,
        unit: package?.unit,
        unitPrice: unitPrice,
        observedAt: observedAt,
        source: source,
        kind: PriceObservationKind.offer,
        validFrom: record.validFrom,
        validUntil: record.validUntil,
        proofRef: record.proofRef,
        discounted: true,
        identityConfidence: confidence,
      ),
    );

    final regular = record.originalPrice;
    if (regular != null) {
      observations.add(
        PriceObservation(
          id: '$prefix|regular|${regular.toStringAsFixed(4)}',
          productId: productId,
          familyKey: identity.familyKey,
          variant: identity.variantKey,
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
          observedAt: observedAt,
          source: source,
          kind: PriceObservationKind.regular,
          validFrom: record.validFrom,
          validUntil: record.validUntil,
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
