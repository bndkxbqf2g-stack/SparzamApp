import '../models/offer.dart';
import '../models/price_observation.dart';
import '../models/receipt_observation.dart';
import '../models/receipt_identity.dart';
import '../features/catalog/product_identity.dart';

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
    kind: receipt.discounted ? PriceObservationKind.offer : PriceObservationKind.unknown,
    proofRef: 'receipt:${receipt.receiptFingerprint}',
    discounted: receipt.discounted,
    identityConfidence: identity.confidence,
  );
}

PriceObservation observationFromOffer(Offer offer, {required DateTime observedAt}) =>
    PriceObservation(
      id: 'offer|${offer.id}|${offer.validUntil.toIso8601String()}|${offer.offerPrice.toStringAsFixed(4)}',
      productId: offer.productId,
      storeName: offer.storeName,
      price: offer.offerPrice,
      observedAt: observedAt,
      source: PriceObservationSource.manual,
      kind: PriceObservationKind.offer,
      validUntil: offer.validUntil,
      proofRef: 'offer:${offer.id}',
      discounted: true,
    );
