import '../../models/market_price.dart';

class MarketPriceImportResult {
  const MarketPriceImportResult({
    required this.prices,
    required this.processed,
    required this.failed,
  });

  final List<MarketPrice> prices;
  final int processed;
  final int failed;
}

Future<MarketPriceImportResult> importMarketPrices({
  required List<MarketPrice> found,
  required List<MarketPrice> current,
  required Future<List<MarketPrice>> Function(MarketPrice) onSave,
}) async {
  var next = current;
  var processed = 0;
  var failed = 0;
  for (final price in found) {
    try {
      next = await onSave(price);
      processed++;
    } catch (_) {
      failed++;
    }
  }
  return MarketPriceImportResult(
    prices: next,
    processed: processed,
    failed: failed,
  );
}
