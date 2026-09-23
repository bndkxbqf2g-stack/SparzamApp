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
    final parsed = _parseLine(line);
    if (parsed == null) {
      unmatched.add(line);
      continue;
    }
    final (name, price) = parsed;
    final normalized = _normalize(name);
    Product? match;
    for (final product in products) {
      final names = [product.name, ...product.aliases].map(_normalize);
      if (names.any(
        (candidate) => candidate == normalized || normalized.contains(candidate),
      )) {
        match = product;
        break;
      }
    }
    if (match == null || price <= 0) {
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

(String, double)? _parseLine(String line) {
  final semicolon = line.lastIndexOf(';');
  if (semicolon > 0) {
    final price = _parsePrice(line.substring(semicolon + 1));
    if (price != null) return (line.substring(0, semicolon).trim(), price);
  }

  final match = RegExp(r'(\d+[,.]\d{2})\s*€?\s*$').firstMatch(line);
  if (match == null) return null;
  final price = _parsePrice(match.group(1)!);
  final name = line.substring(0, match.start).trim();
  if (price == null || name.isEmpty) return null;
  return (name, price);
}

double? _parsePrice(String value) => double.tryParse(
      value.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''),
    );

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9äöüß ]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
