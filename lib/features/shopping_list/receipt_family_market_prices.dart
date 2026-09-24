import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/receipt_observation.dart';
import '../receipt/receipt_observation_builder.dart';
import '../catalog/product_family.dart';
import '../../services/quantity_normalizer.dart';

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
  int maxAgeDays = 90,
}) {
  final today = now ?? DateTime.now();
  final cutoff = DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: maxAgeDays));
  final result = <String, MarketPrice>{};

  for (final item in items) {
    final family = inferReceiptFamily(item.product.name);
    if (family.isEmpty) continue;
    final productName = _normalize(item.product.name);
    final isGenericRequest = productName == family ||
        isGenericFamilyRequest(item.product.name);

    for (final observation in observations) {
      if (observation.observedAt.isBefore(cutoff) ||
          inferReceiptFamily(observation.rawLabel) != family) {
        continue;
      }
      final raw = _normalize(observation.rawLabel);
      final exactIdentity = productName == raw ||
          item.product.aliases.any((alias) => _normalize(alias) == raw);
      if (!isGenericRequest && !exactIdentity) continue;
      final price = _comparablePrice(item, observation);
      if (price == null || !price.isFinite || price <= 0) continue;
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
          discounted: observation.discounted,
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


double? _comparablePrice(ListItem item, ReceiptObservation observation) {
  final packageAmount = item.product.packageAmount;
  final packageUnit = item.product.packageUnit;
  if (packageAmount == null || packageUnit == null) {
    // A generic request has no safe package basis. Keep historical family
    // evidence out of route totals instead of comparing arbitrary pack prices.
    return null;
  }
  final receiptAmount = observation.quantity?.toDouble();
  final receiptUnit = observation.quantityUnit;
  if (receiptAmount == null || receiptUnit.isEmpty) return null;
  final wanted = normalizeQuantity(packageAmount, packageUnit);
  final seen = normalizeQuantity(receiptAmount, receiptUnit);
  if (wanted == null || seen == null || wanted.dimension != seen.dimension) {
    return null;
  }
  final perBase = normalizedUnitPrice(
    observation.totalPrice,
    receiptAmount,
    receiptUnit,
  );
  if (perBase == null) return null;
  return perBase * wanted.amount;
}
