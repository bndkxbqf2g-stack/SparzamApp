import '../../models/receipt_observation.dart';
import 'receipt_observation_builder.dart';

/// Re-runs current product-family inference over immutable receipt evidence.
/// Raw labels, prices and explicit identity confirmations are preserved.
ReceiptObservation reinterpretReceiptObservation(ReceiptObservation source) {
  final familyKey = inferReceiptFamily(source.rawLabel);
  if (familyKey == source.familyKey) return source;

  return ReceiptObservation(
    id: source.id,
    receiptFingerprint: source.receiptFingerprint,
    rowLine: source.rowLine,
    rawLabel: source.rawLabel,
    familyKey: familyKey,
    storeName: source.storeName,
    observedAt: source.observedAt,
    totalPrice: source.totalPrice,
    quantity: source.quantity,
    quantityUnit: source.quantityUnit,
    unitPrice: source.unitPrice,
    discounted: source.discounted,
    productId: source.productId,
    identityConfirmed: source.identityConfirmed,
  );
}

List<ReceiptObservation> reinterpretReceiptObservations(
  Iterable<ReceiptObservation> observations,
) =>
    observations.map(reinterpretReceiptObservation).toList(growable: false);
