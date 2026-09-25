import '../../models/market_price.dart';
import '../../models/product.dart';
import '../catalog/product_identity.dart';
import 'receipt_ledger.dart';

class ReceiptPriceSuggestion {
  const ReceiptPriceSuggestion({
    required this.product,
    required this.row,
    required this.price,
  });

  final Product product;
  final ReceiptRow row;
  final MarketPrice price;
}

class ReceiptPriceReview {
  const ReceiptPriceReview({
    required this.suggestions,
    required this.unmatchedItems,
  });

  final List<ReceiptPriceSuggestion> suggestions;
  final int unmatchedItems;
}

ReceiptPriceReview reviewReceiptPrices(
  ReceiptDraft draft,
  List<Product> products,
) {
  final items = draft.rows.where((row) => row.kind == ReceiptRowKind.item).toList();
  if (!draft.balances || draft.retailer == null || draft.receiptDate == null) {
    return ReceiptPriceReview(suggestions: const [], unmatchedItems: items.length);
  }
  final discounted = draft.rows
      .where((row) => row.kind == ReceiptRowKind.discount)
      .map((row) => row.linkedItemLine)
      .whereType<int>()
      .toSet();
  final unresolved = draft.unresolvedLines.toSet();
  final candidates = <ReceiptPriceSuggestion>[];
  for (final row in items) {
    if (discounted.contains(row.line) || unresolved.contains(row.line)) continue;
    final product = _matchProduct(row, products);
    if (product == null) continue;
    final unitCents = row.quantity == null ? row.cents : row.unitCents;
    if (unitCents == null || unitCents <= 0 ||
        (row.quantity != null &&
            (row.quantity! * unitCents).round() != row.cents) ||
        (row.quantity == null &&
            RegExp(r'\b\d+[,.]\d+\s*kg\b').hasMatch(row.label))) {
      continue;
    }
    candidates.add(ReceiptPriceSuggestion(
      product: product,
      row: row,
      price: MarketPrice(
        productId: product.id,
        storeName: draft.retailer!,
        price: unitCents / 100,
        updatedAt: draft.receiptDate!,
        source: MarketPriceSource.receipt,
      ),
    ));
  }

  final byProduct = <String, List<ReceiptPriceSuggestion>>{};
  for (final candidate in candidates) {
    byProduct.putIfAbsent(candidate.product.id, () => []).add(candidate);
  }
  final unique = <ReceiptPriceSuggestion>[];
  for (final entries in byProduct.values) {
    if (entries.map((e) => e.row.label.toLowerCase().trim()).toSet().length == 1 &&
        entries.map((e) => e.price.price).toSet().length == 1) {
      unique.add(entries.first);
    }
  }
  return ReceiptPriceReview(
    suggestions: unique,
    unmatchedItems: items.length - unique.length,
  );
}

Product? _matchProduct(ReceiptRow row, List<Product> products) {
  final identity = identifyProduct(row.label);
  final matches = products.where((product) {
    final candidate = identifyProduct(product.name);
    final exact = normalizeIdentityText(product.name) ==
        normalizeIdentityText(row.label);
    return exact ||
        (identity.isKnown && compatibleProductIdentity(candidate, identity));
  }).toList();
  return matches.length == 1 ? matches.single : null;
}
