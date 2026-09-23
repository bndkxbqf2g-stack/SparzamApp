import '../../models/market_price.dart';
import '../../models/product.dart';

class ReceiptImportResult {
  const ReceiptImportResult({required this.prices, required this.unmatchedLines});

  final List<MarketPrice> prices;
  final List<String> unmatchedLines;
}

ReceiptImportResult parseReceiptLines({
  required String text,
  required String storeName,
  required List<Product> products,
  DateTime? now,
}) {
  final timestamp = now ?? DateTime.now();
  final prices = <MarketPrice>[];
  final unmatched = <String>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final parts = line.split(';');
    if (parts.length < 2) {
      unmatched.add(line);
      continue;
    }
    final name = parts.first.trim();
    final priceText = parts.sublist(1).join(';').replaceAll(',', '.').trim();
    final price = double.tryParse(priceText.replaceAll(RegExp(r'[^0-9.]'), ''));
    final normalized = _normalize(name);
    Product? match;
    for (final product in products) {
      if (_normalize(product.name) == normalized ||
          product.aliases.any((alias) => _normalize(alias) == normalized)) {
        match = product;
        break;
      }
    }
    if (match == null || price == null || price <= 0) {
      unmatched.add(line);
      continue;
    }
    prices.add(MarketPrice(
      productId: match.id,
      storeName: storeName.trim(),
      price: price,
      updatedAt: timestamp,
      source: MarketPriceSource.receipt,
    ));
  }
  return ReceiptImportResult(prices: prices, unmatchedLines: unmatched);
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9äöüß ]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
