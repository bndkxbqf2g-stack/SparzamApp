import 'package:flutter/material.dart';

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


/// Presents the bounded candidate list used next to an unresolved receipt row.
/// Selecting a chip only reports the user's explicit choice to the caller.
class ReceiptProductSuggestionList extends StatelessWidget {
  const ReceiptProductSuggestionList({
    super.key,
    required this.rawLabel,
    required this.products,
    required this.onSelected,
    this.enabled = true,
  });

  final String rawLabel;
  final List<Product> products;
  final ValueChanged<Product> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final candidates = receiptProductCandidates(
      rawLabel: rawLabel,
      products: products,
    );
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mögliche Katalogtreffer – bitte ausdrücklich auswählen:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final candidate in candidates)
                ActionChip(
                  label: Text(candidate.product.name),
                  onPressed: enabled
                      ? () => onSelected(candidate.product)
                      : null,
                ),
            ],
          ),
          const Text(
            'Die Auswahl bestätigt nur diese Bon-Zuordnung. Preis und Packungsgröße bleiben separat geprüft.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
