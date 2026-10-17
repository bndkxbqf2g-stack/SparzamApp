import '../models/offer.dart';
import '../models/price_observation.dart';
import '../models/receipt_observation.dart';
import '../models/receipt_identity.dart';
import '../features/catalog/product_identity.dart';
import '../features/offers/offer_import.dart';
import 'quantity_normalizer.dart';

/// Keeps a source-provided capture time when an offer enters price history.
/// Legacy/manual offers without one use the caller's local fallback time.
DateTime observedAtForOffer(Offer offer, {required DateTime fallback}) =>
    offer.capturedAt ?? fallback;

PriceObservation observationFromReceipt(ReceiptObservation receipt) {
  final identity = assessReceiptIdentity(
    productId: receipt.productId,
    identityConfirmed: receipt.identityConfirmed,
    familyKey: receipt.familyKey,
  );
  return PriceObservation(
    id: 'receipt|${receipt.id}',
    productId: receipt.productId,
    familyKey: receipt.familyKey,
    variant: identifyProduct(receipt.rawLabel).variantKey,
    storeName: receipt.storeName,
    price: receipt.totalPrice,
    quantity: receipt.quantity?.toDouble(),
    unit: receipt.quantityUnit,
    unitPrice: receipt.unitPrice,
    observedAt: receipt.observedAt,
    source: PriceObservationSource.receipt,
    kind: receipt.discounted
        ? PriceObservationKind.offer
        : PriceObservationKind.regular,
    proofRef: 'receipt:${receipt.receiptFingerprint}',
    discounted: receipt.discounted,
    identityConfidence: identity.confidence,
  );
}

PriceObservation observationFromOffer(
  Offer offer, {
  required DateTime observedAt,
}) => PriceObservation(
  id: 'offer|${offer.id}|${offer.validUntil.toIso8601String()}|${offer.offerPrice.toStringAsFixed(4)}',
  productId: offer.productId,
  storeName: offer.storeName,
  price: offer.offerPrice,
  quantity: offer.packageAmount,
  unit: offer.packageUnit,
  unitPrice: offer.unitPrice ??
      normalizedUnitPrice(
        price: offer.offerPrice,
        amount: offer.packageAmount,
        unit: offer.packageUnit,
      ),
  observedAt: observedAt,
  source: _offerSource(offer),
  sourceAdapter: offer.sourceAdapter,
  kind: PriceObservationKind.offer,
  validFrom: offer.validFrom,
  validUntil: offer.validUntil,
  locationId: offer.locationId,
  region: offer.region,
  proofRef: offer.proofRef ?? 'offer:${offer.id}',
  discounted: true,
  identityConfidence: _offerIdentityConfidence(offer),
  evidenceConfidence: offer.evidenceConfidence,
);

PriceObservation regularObservationFromOffer(
  Offer offer, {
  required DateTime observedAt,
}) => PriceObservation(
  id: 'offer-regular|${offer.id}|${offer.originalPrice.toStringAsFixed(4)}',
  productId: offer.productId,
  storeName: offer.storeName,
  price: offer.originalPrice,
  quantity: offer.packageAmount,
  unit: offer.packageUnit,
  unitPrice: normalizedUnitPrice(
    price: offer.originalPrice,
    amount: offer.packageAmount,
    unit: offer.packageUnit,
  ),
  observedAt: observedAt,
  source: _offerSource(offer),
  sourceAdapter: offer.sourceAdapter,
  regularPriceSource: offer.regularPriceSource,
  kind: PriceObservationKind.regular,
  validFrom: offer.validFrom,
  validUntil: offer.validUntil,
  locationId: offer.locationId,
  region: offer.region,
  proofRef: offer.proofRef ?? 'offer:${offer.id}',
  identityConfidence: offer.originalPriceVerified
      ? _offerIdentityConfidence(offer)
      : 0,
  evidenceConfidence: offer.evidenceConfidence,
);

Iterable<PriceObservation> observationsFromOffer(
  Offer offer, {
  required DateTime observedAt,
}) sync* {
  if (offer.originalPriceVerified) {
    yield regularObservationFromOffer(offer, observedAt: observedAt);
  }
  yield observationFromOffer(offer, observedAt: observedAt);
}

double _offerIdentityConfidence(Offer offer) {
  return hasTrustedOfferEvidence(offer) && hasExactOfferBranch(offer) ? 1 : 0;
}

PriceObservationSource _offerSource(Offer offer) =>
    switch (canonicalProspectSourceToken(offer.source)) {
      'retailer' => PriceObservationSource.retailer,
      'retailerWebsite' => PriceObservationSource.retailerWebsite,
      'leaflet' => PriceObservationSource.leaflet,
      _ => PriceObservationSource.manual,
    };

