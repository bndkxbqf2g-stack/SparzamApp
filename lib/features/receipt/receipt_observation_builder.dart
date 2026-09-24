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
  // Only an explicit user assignment establishes exact product identity.
  // Automatic review suggestions remain family evidence until confirmed.
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

/// Conservative family inference. It enables generic shopping-list terms without
/// pretending that an abbreviated receipt line identifies a precise variant.
String inferReceiptFamily(String label) {
  final value = label
      .toLowerCase()
      .replaceAll(RegExp(r'[._-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final broad = broadProductFamily(value);
  if (broad != null) return broad;

  const families = <String, List<String>>{
    'hackfleisch': [
      'hackfleisch',
      'hackfl gem',
      'r hackfleisch',
      'rinderhack',
    ],
    'milch': ['h milch', 'vollmilch', 'milch 1,5', 'milch 3,5'],
    'weintrauben': ['weintrauben', 'trauben'],
    'bananen': ['bananen'],
    'kartoffeln': ['kartoffeln'],
    'paprika': ['paprika'],
    'eier': ['eier'],
    'fischstäbchen': ['fischstäbchen'],
    'schmand': ['schmand'],
    'joghurt': ['joghurt'],
    'toast': ['sandwichtoast', 'toast'],
  };
  for (final entry in families.entries) {
    if (entry.value.any(value.contains)) return entry.key;
  }

  // Unknown items remain searchable by a stable normalized receipt label.
  return value
      .replaceAll(RegExp(r'\b\d+(?:[,.]\d+)?\s*(?:g|kg|ml|l)\b'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
