import '../../models/market_price.dart';
import '../../models/product.dart';
import 'receipt_ledger.dart';

bool isAmbiguousKauflandMilk(ReceiptDraft draft, ReceiptRow row) =>
    draft.retailer == 'Kaufland' &&
    row.kind == ReceiptRowKind.item &&
    row.label.trim().toLowerCase() == 'k.h-milch';

/// An abbreviation alone does not establish fat content or brand.
MarketPrice? assignedKauflandMilkPrice({
  required ReceiptDraft draft,
  required ReceiptRow row,
  required Product product,
}) {
  if (!draft.balances || draft.receiptDate == null ||
      !isAmbiguousKauflandMilk(draft, row) ||
      !{'milch_15', 'milch_35'}.contains(product.id) ||
      product.unit != '1 l' ||
      draft.rows.any((entry) => entry.kind == ReceiptRowKind.discount &&
          entry.linkedItemLine == row.line) ||
      draft.unresolvedLines.contains(row.line)) {
    return null;
  }
  final unitCents = row.quantity == null ? row.cents : row.unitCents;
  if (unitCents == null || unitCents <= 0 ||
      (row.quantity != null &&
          (row.quantity! * unitCents).round() != row.cents)) {
    return null;
  }
  return MarketPrice(
    productId: product.id,
    storeName: draft.retailer!,
    price: unitCents / 100,
    updatedAt: draft.receiptDate!,
    source: MarketPriceSource.receipt,
  );
}
