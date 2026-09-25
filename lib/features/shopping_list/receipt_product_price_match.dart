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
  final family = inferReceiptFamily(product.name);
  final generic = family.isNotEmpty && isGenericFamilyRequest(product.name);

  // A generic shopping request represents the whole product family. Do not
  // stop at exact product IDs, otherwise older receipt rows that were assigned
  // to provisional/sibling catalog IDs disappear from the family history.
  if (generic) {
    return stats.where((stat) => stat.familyKey == family).toList();
  }

  // Specific variants may only use their exact assigned history. Falling back
  // to a broad family here would let e.g. mixed mince satisfy beef mince.
  return stats.where((stat) => stat.productId == product.id).toList();
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
