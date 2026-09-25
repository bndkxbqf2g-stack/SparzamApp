import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../receipt/receipt_observation_builder.dart';
import '../catalog/product_family.dart';

/// Finds receipt statistics for a shopping-list product while preserving the
/// distinction between generic family requests and specific variants.
List<ReceiptPriceStat> receiptStatsForProduct(
  Product product,
  Iterable<ReceiptPriceStat> stats,
) {
  final exact = stats.where((stat) => stat.productId == product.id).toList();
  if (exact.isNotEmpty) return exact;

  final family = inferReceiptFamily(product.name);
  if (family.isEmpty || !isGenericFamilyRequest(product.name)) {
    return const <ReceiptPriceStat>[];
  }
  return stats.where((stat) => stat.familyKey == family).toList();
}

ReceiptPriceStat? preferredReceiptStatForProduct(
  Product product,
  Iterable<ReceiptPriceStat> stats,
) {
  final matches = receiptStatsForProduct(product, stats);
  if (matches.isEmpty) return null;

  final comparable = matches.where((stat) => stat.comparable).toList();
  if (comparable.isNotEmpty) {
    comparable.sort((a, b) => a.medianPrice.compareTo(b.medianPrice));
    return comparable.first;
  }

  matches.sort((a, b) => b.latestAt.compareTo(a.latestAt));
  return matches.first;
}
