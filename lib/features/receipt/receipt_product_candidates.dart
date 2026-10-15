import '../../models/product.dart';
import '../catalog/product_match_candidates.dart';

/// Returns a small, explicit set of catalog suggestions for an unresolved
/// receipt label.
///
/// Suggestions remain evidence only. The caller must keep the manual tap that
/// assigns a product to the receipt row; no candidate is promoted implicitly.
List<ProductCandidate> receiptProductCandidates({
  required String rawLabel,
  required List<Product> products,
  int limit = 3,
}) {
  if (limit <= 0 || rawLabel.trim().isEmpty || products.isEmpty) {
    return const <ProductCandidate>[];
  }
  return suggestProducts(
    ProductQuery(label: rawLabel),
    products,
  ).where((candidate) {
    // A category-only match is too broad for a receipt assignment. It remains
    // useful in catalog discovery, but must not be presented as a likely
    // identity beside a concrete paid receipt line.
    return candidate.relation != CandidateRelation.categoryOnly;
  }).take(limit).toList(growable: false);
}
