import '../../models/market_price.dart';
import '../../models/product.dart';
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

/// Promote only balanced receipt lines whose product and package are certain.
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
    final unitCents = row.quantity == null
        ? row.cents
        : row.unitCents;
    if (unitCents == null || unitCents <= 0 || row.quantity != null &&
        (row.quantity! * unitCents).round() != row.cents) {
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
  // Different variants of the same catalog item must never overwrite each other.
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
  final normalized = _normalize(row.label);
  // Some receipt abbreviations identify a package unambiguously. Bare
  // "K.H-Milch" cannot distinguish 1.5% from 3.5% and is excluded.
  String? knownProductId;
  if (normalized == 'bananen lose mt' &&
      row.quantityUnit == 'kg' && row.unitCents != null) {
    knownProductId = 'bananen';
  } else if (RegExp(r'^trauben 500g(?: hell| dunkel)?$').hasMatch(normalized)) {
    knownProductId = 'weintrauben';
  } else if (RegExp(r'^gl h-milch 3,5% 1 ?l$').hasMatch(normalized)) {
    knownProductId = 'milch_35';
  } else if (RegExp(r'^hackfleisch gemischt 500g$').hasMatch(normalized)) {
    knownProductId = 'hackfleisch';
  }
  if (knownProductId != null) {
    final matches = products.where((p) => p.id == knownProductId).toList();
    return matches.length == 1 ? matches.single : null;
  }
  final matches = products.where((product) =>
      _normalize(product.name) == normalized &&
      !RegExp(r'\d+[,.]\d+\s*kg').hasMatch(normalized)).toList();
  return matches.length == 1 ? matches.single : null;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
