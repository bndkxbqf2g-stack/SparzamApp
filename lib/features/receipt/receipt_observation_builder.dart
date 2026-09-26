import '../../models/receipt_observation.dart';
import 'receipt_ledger.dart';
import 'receipt_price_review.dart';
import '../catalog/product_family.dart';
import '../../data/stores.dart';
import '../../services/store_identity.dart';

List<ReceiptObservation> buildReceiptObservations({
  required ReceiptDraft draft,
  required ReceiptPriceReview review,
  Map<int, String> assignedProductIds = const <int, String>{},
  Set<int> confirmedProductLines = const <int>{},
}) {
  // A total mismatch must not discard otherwise valid item observations. The
  // ledger already marks unusable rows via unresolvedLines and the price
  // review filters those rows individually.
  if (draft.retailer == null || draft.receiptDate == null) {
    return const <ReceiptObservation>[];
  }
  final matched = <int, String>{...assignedProductIds};
  final discountedLines = draft.rows
      .where((row) => row.kind == ReceiptRowKind.discount)
      .map((row) => row.linkedItemLine)
      .whereType<int>()
      .toSet();
  final unresolvedLines = draft.unresolvedLines.toSet();
  final storeName = canonicalStoreName(draft.retailer, stores) ?? draft.retailer!;

  return draft.rows
      .where((row) => row.kind == ReceiptRowKind.item &&
          !unresolvedLines.contains(row.line))
      .map((row) => ReceiptObservation(
            id: '${draft.fingerprint}|${row.line}',
            receiptFingerprint: draft.fingerprint,
            rowLine: row.line,
            rawLabel: row.label,
            familyKey: inferReceiptFamily(row.label),
            storeName: storeName,
            observedAt: draft.receiptDate!,
            totalPrice: row.cents / 100,
            quantity: row.quantity,
            quantityUnit: row.quantityUnit,
            unitPrice: row.unitCents == null ? null : row.unitCents! / 100,
            discounted: discountedLines.contains(row.line),
            productId: matched[row.line],
            identityConfirmed: confirmedProductLines.contains(row.line),
          ))
      .toList();
}

/// Family inference is a projection of the general identity resolver.
String inferReceiptFamily(String label) {
  final identity = identifyProduct(label);
  if (identity.familyKey != null) return identity.familyKey!;
  return normalizeIdentityText(label)
      .replaceAll(RegExp(r'\b\d+(?:[,.]\d+)?\s*(?:g|kg|ml|l)\b'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
