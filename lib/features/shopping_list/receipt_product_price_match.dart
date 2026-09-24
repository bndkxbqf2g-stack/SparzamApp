import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../receipt/receipt_observation_builder.dart';
import '../catalog/product_family.dart';

/// Finds receipt statistics for a shopping-list product without pretending
/// that a broader family observation is an exact variant match.
///
/// Exact product history wins. Otherwise an unassigned family observation may
/// be used as a conservative historical hint for the same family, including
/// older observations already linked to a different concrete catalog identity.
List<ReceiptPriceStat> receiptStatsForProduct(
  Product product,
  Iterable<ReceiptPriceStat> stats,
) {
  final exact = stats.where((stat) => stat.productId == product.id).toList();
  if (exact.isNotEmpty) return exact;

  if (!isGenericFamilyRequest(product.name)) return const <ReceiptPriceStat>[];

  final family = inferReceiptFamily(product.name);
  return stats
      .where((stat) => stat.familyKey == family)
      .toList();
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

  // A non-comparable pack price must not become a fake "cheapest" result.
  matches.sort((a, b) => b.latestAt.compareTo(a.latestAt));
  return matches.first;
}
