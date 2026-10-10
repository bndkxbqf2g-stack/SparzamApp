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
  if (!draft.balances || draft.retailer == null || draft.receiptDate == null) {
    return const <ReceiptObservation>[];
  }
  final matched = <int, String>{...assignedProductIds};
  final discountedLines = draft.rows
      .where((row) => row.kind == ReceiptRowKind.discount)
      .map((row) => row.linkedItemLine)
      .whereType<int>()
      .toSet();
  final storeName =
      canonicalStoreName(draft.retailer, stores) ?? draft.retailer!;
  var itemOrdinal = 0;

  return draft.rows.where((row) => row.kind == ReceiptRowKind.item).map((row) {
    itemOrdinal++;
    return ReceiptObservation(
      // The source line is evidence, not identity: OCR/PDF extraction can
      // insert or remove layout lines while the priced ledger stays the
      // same. The ordinal keeps repeated identical items distinct without
      // creating a new observation for that harmless layout change.
      id: '${draft.fingerprint}|item:$itemOrdinal',
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
    );
  }).toList();
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
