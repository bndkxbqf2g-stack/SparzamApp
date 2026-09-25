import '../../models/receipt_observation.dart';
import 'receipt_ledger.dart';
import 'receipt_price_review.dart';
import '../catalog/product_family.dart';

List<ReceiptObservation> buildReceiptObservations({
  required ReceiptDraft draft,
  required ReceiptPriceReview review,
  Map<int, String> assignedProductIds = const <int, String>{},
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

  return draft.rows
      .where((row) => row.kind == ReceiptRowKind.item)
      .map((row) => ReceiptObservation(
            id: '${draft.fingerprint}|${row.line}',
            receiptFingerprint: draft.fingerprint,
            rowLine: row.line,
            rawLabel: row.label,
            familyKey: inferReceiptFamily(row.label),
            storeName: draft.retailer!,
            observedAt: draft.receiptDate!,
            totalPrice: row.cents / 100,
            quantity: row.quantity,
            quantityUnit: row.quantityUnit,
            unitPrice: row.unitCents == null ? null : row.unitCents! / 100,
            discounted: discountedLines.contains(row.line),
            productId: matched[row.line],
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
