import '../../models/product.dart';
import '../../models/receipt_price_stat.dart';
import '../receipt/receipt_observation_builder.dart';
import '../catalog/product_family.dart';

/// Finds confirmed receipt statistics for a shopping-list product.
///
/// This is the strict view used by price selection and route-related callers.
List<ReceiptPriceStat> receiptStatsForProduct(
  Product product,
  Iterable<ReceiptPriceStat> stats,
) {
  final family = inferReceiptFamily(product.name);
  final generic = family.isNotEmpty && isGenericFamilyRequest(product.name);

  if (generic) {
    return stats
        .where((stat) => stat.familyKey == family && stat.identityConfirmed)
        .toList();
  }

  return stats
      .where((stat) => stat.productId == product.id && stat.identityConfirmed)
      .toList();
}

/// Returns all receipt history that can be shown as a transparent hint.
///
/// Unconfirmed automatic receipt assignments are deliberately visible here so
/// users do not lose imported prices. They remain labelled as provisional and
/// are never promoted to route prices by this view.
List<ReceiptPriceStat> receiptHintsForProduct(
  Product product,
  Iterable<ReceiptPriceStat> stats,
) {
  final family = inferReceiptFamily(product.name);
  final generic = family.isNotEmpty && isGenericFamilyRequest(product.name);

  if (generic) {
    return stats.where((stat) => stat.familyKey == family).toList();
  }

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
