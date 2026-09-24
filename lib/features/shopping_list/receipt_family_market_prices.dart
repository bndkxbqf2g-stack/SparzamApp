import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/receipt_observation.dart';
import '../receipt/receipt_observation_builder.dart';

/// Bridges receipt history into the common market-price pipeline used by the
/// shopping list and route optimizer.
///
/// Exact product prices remain preferred elsewhere. This fallback is only
/// created when the shopping-list product and receipt row resolve to the same
/// conservative product family. The newest observation per store is used.
List<MarketPrice> receiptFamilyMarketPrices({
  required Iterable<ListItem> items,
  required Iterable<ReceiptObservation> observations,
  DateTime? now,
  int maxAgeDays = 30,
}) {
  final today = now ?? DateTime.now();
  final cutoff = DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: maxAgeDays));
  final result = <String, MarketPrice>{};

  for (final item in items) {
    final family = inferReceiptFamily(item.product.name);
    if (family.isEmpty) continue;
    final productName = _normalize(item.product.name);
    final isGenericRequest = productName == family;

    for (final observation in observations) {
      if (observation.observedAt.isBefore(cutoff) ||
          inferReceiptFamily(observation.rawLabel) != family) {
        continue;
      }
      final raw = _normalize(observation.rawLabel);
      final exactIdentity = productName == raw ||
          item.product.aliases.any((alias) => _normalize(alias) == raw);
      if (!isGenericRequest && !exactIdentity) continue;
      final price = observation.unitPrice ?? observation.totalPrice;
      if (!price.isFinite || price <= 0) continue;
      final key = '${observation.storeName}|${item.product.id}';
      final previous = result[key];
      if (previous == null ||
          observation.observedAt.isAfter(previous.updatedAt)) {
        result[key] = MarketPrice(
          productId: item.product.id,
          storeName: observation.storeName,
          price: price,
          updatedAt: observation.observedAt,
          source: MarketPriceSource.receipt,
        );
      }
    }
  }
  return result.values.toList();
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[._-]+'), ' ')
    .replaceAll(RegExp(r'\\s+'), ' ')
    .trim();
