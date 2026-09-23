import '../../models/market_price.dart';
import '../../models/product.dart';

class ReceiptImportResult {
  const ReceiptImportResult({required this.prices, required this.unmatchedLines});

  final List<MarketPrice> prices;
  final List<String> unmatchedLines;
}

class ReceiptImportOutcome {
  const ReceiptImportOutcome({
    required this.savedPrices,
    required this.unmatchedLines,
  });

  final int savedPrices;
  final List<String> unmatchedLines;
}

/// Only explicitly reviewed name;unit-price entries are eligible for learning.
/// Raw receipt text needs a store-specific parser, quantity and discount checks.
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
    final parsed = _parseReviewedLine(line);
    if (parsed == null) {
      unmatched.add(line);
      continue;
    }
    final (name, price) = parsed;
    final normalized = _normalize(name);
    final matches = products.where((product) {
      final names = [product.name, ...product.aliases].map(_normalize);
      return names.contains(normalized);
    }).toList();
    if (matches.length != 1 || price <= 0) {
      unmatched.add(line);
      continue;
    }
    prices.add(MarketPrice(
      productId: matches.single.id,
      storeName: storeName.trim(),
      price: price,
      updatedAt: timestamp,
      source: MarketPriceSource.receipt,
    ));
  }
  return ReceiptImportResult(prices: prices, unmatchedLines: unmatched);
}

(String, double)? _parseReviewedLine(String line) {
  final match = RegExp(r'^([^;]+);([0-9]+[,.][0-9]{2})$').firstMatch(line);
  if (match == null) return null;
  final name = match.group(1)!.trim();
  final price = double.tryParse(match.group(2)!.replaceAll(',', '.'));
  if (name.isEmpty || price == null) return null;
  return (name, price);
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9äöüß ]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
