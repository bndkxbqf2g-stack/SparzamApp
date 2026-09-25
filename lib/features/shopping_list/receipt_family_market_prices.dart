import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/receipt_observation.dart';
import '../catalog/product_identity.dart';
import '../../services/quantity_normalizer.dart';

/// Bridges receipt history into the common market-price pipeline.
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
    final request = identifyProduct(item.product.name);
    final normalizedRequest = normalizeIdentityText(item.product.name);
    if (!request.isKnown && normalizedRequest.isEmpty) continue;

    for (final observation in observations) {
      if (observation.observedAt.isBefore(cutoff)) continue;
      final candidate = identifyProduct(observation.rawLabel);
      final normalizedCandidate = normalizeIdentityText(observation.rawLabel);
      final exact = normalizedRequest == normalizedCandidate ||
          item.product.aliases.any(
            (alias) => normalizeIdentityText(alias) == normalizedCandidate,
          );
      final compatible = request.isKnown &&
          compatibleProductIdentity(request, candidate);
      if (!exact && !compatible) continue;

      final price = _comparablePrice(item, observation);
      if (price == null || !price.isFinite || price <= 0) continue;
      final key = '${observation.storeName}|${item.product.id}';
      final previous = result[key];
      if (previous == null || observation.observedAt.isAfter(previous.updatedAt)) {
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

double? _comparablePrice(ListItem item, ReceiptObservation observation) {
  final packageAmount = item.product.packageAmount;
  final packageUnit = item.product.packageUnit;
  if (packageAmount == null || packageUnit == null) {
    // A normal single receipt row has no explicit quantity but still carries
    // the parser's default "Stück" unit. It is a valid observed package price.
    if (observation.quantity == null) {
      return observation.totalPrice;
    }
    // "2 x 2,49" describes two identical purchased packages. For a generic
    // shopping-list item compare one package, not the summed receipt line.
    if (observation.quantityUnit == 'Stück' &&
        observation.unitPrice != null &&
        observation.unitPrice!.isFinite &&
        observation.unitPrice! > 0) {
      return observation.unitPrice;
    }
    // Weight/volume observations cannot be projected to a generic product
    // without a requested package basis.
    return null;
  }
  final receiptAmount = observation.quantity?.toDouble();
  final receiptUnit = observation.quantityUnit;
  if (receiptAmount == null || receiptUnit.isEmpty) return null;
  final wanted = normalizeQuantity(packageAmount, packageUnit);
  final seen = normalizeQuantity(receiptAmount, receiptUnit);
  if (wanted == null || seen == null || wanted.dimension != seen.dimension) return null;
  final perBase = normalizedUnitPrice(
    price: observation.totalPrice,
    amount: receiptAmount,
    unit: receiptUnit,
  );
  if (perBase == null) return null;
  return perBase * wanted.amount;
}
