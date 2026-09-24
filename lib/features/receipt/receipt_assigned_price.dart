import '../../models/market_price.dart';
import '../../models/product.dart';
import 'receipt_ledger.dart';
import 'receipt_milk_assignment.dart';

/// Converts an exact receipt identity into a direct market price when the
/// receipt itself provides a safe price basis.
MarketPrice? assignedReceiptPrice({
  required ReceiptDraft draft,
  required ReceiptRow row,
  required Product product,
}) {
  final milk = assignedKauflandMilkPrice(
    draft: draft,
    row: row,
    product: product,
  );
  if (milk != null) return milk;

  if (!draft.balances ||
      draft.retailer == null ||
      draft.receiptDate == null ||
      row.kind != ReceiptRowKind.item ||
      draft.unresolvedLines.contains(row.line)) {
    return null;
  }

  final raw = _normalize(row.label);
  final exactIdentity = _normalize(product.name) == raw ||
      product.aliases.any((alias) => _normalize(alias) == raw);
  if (!exactIdentity) return null;

  final cents = row.quantity == null ? row.cents : row.unitCents;
  if (cents == null || cents <= 0) return null;

  return MarketPrice(
    productId: product.id,
    storeName: draft.retailer!,
    price: cents / 100,
    updatedAt: draft.receiptDate!,
    source: MarketPriceSource.receipt,
    discounted: draft.rows.any((entry) =>
        entry.kind == ReceiptRowKind.discount &&
        entry.linkedItemLine == row.line),
  );
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[._-]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
