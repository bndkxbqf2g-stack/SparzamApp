import '../../models/product.dart';
import 'product_hierarchy.dart';
import 'product_identity.dart';

/// A catalog hit retains the identity-derived family path used for display and
/// ranking. It is a search result only; it never confirms a price or variant.
class ProductCatalogSearchResult {
  const ProductCatalogSearchResult({
    required this.product,
    required this.hierarchy,
    required this.score,
  });

  final Product product;
  final ProductHierarchyLabel hierarchy;
  final int score;
}

/// Returns catalog products in a deterministic, identity-aware order.
///
/// Known grocery terms use the shared product identity resolver. Compatible
/// variants stay together, while related but different identities (for example
/// fresh tomatoes versus passata) are left out of the primary result. Unknown
/// text still searches brand, group, aliases and EAN so custom products remain
/// discoverable without a second alias system.
List<Product> buildProductCatalogSearchResults({
  required String query,
  required Iterable<Product> products,
}) {
  final normalizedQuery = query.trim();
  final queryIdentity = identifyProduct(normalizedQuery);
  final results = <ProductCatalogSearchResult>[];

  for (final product in products) {
    final hierarchy = productHierarchyLabel(product);
    final score = _catalogMatchScore(
      product: product,
      query: normalizedQuery,
      queryIdentity: queryIdentity,
      hierarchy: hierarchy,
    );
    if (score == null) continue;
    results.add(
      ProductCatalogSearchResult(
        product: product,
        hierarchy: hierarchy,
        score: score,
      ),
    );
  }

  results.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byPath = a.hierarchy.path.compareTo(b.hierarchy.path);
    if (byPath != 0) return byPath;
    final byName = a.product.name.compareTo(b.product.name);
    if (byName != 0) return byName;
    return a.product.id.compareTo(b.product.id);
  });
  return results.map((result) => result.product).toList(growable: false);
}

int? _catalogMatchScore({
  required Product product,
  required String query,
  required ProductIdentity queryIdentity,
  required ProductHierarchyLabel hierarchy,
}) {
  if (query.isEmpty) {
    return (product.isFavorite ? 20 : 0) + (product.isStaple ? 10 : 0);
  }

  final normalized = normalizeIdentityText(query);
  final labels = <String>[
    product.name,
    product.brand ?? '',
    product.group,
    ...product.aliases,
    product.ean ?? '',
  ];
  final searchable = labels
      .map(normalizeIdentityText)
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  final textMatch = searchable.any(
    (value) => value == normalized || value.contains(normalized),
  );

  if (queryIdentity.isKnown) {
    final identities = <ProductIdentity>[
      identifyProduct(product.name),
      ...product.aliases.map(identifyProduct),
    ].where((identity) => identity.isKnown);
    final identityMatch = identities.any(
      (candidate) => compatibleProductIdentity(queryIdentity, candidate),
    );
    if (!identityMatch) return null;
    final exactLabel = searchable.any((value) => value == normalized);
    return (exactLabel ? 1_000 : 800) +
        (textMatch ? 40 : 0) +
        (product.isFavorite ? 20 : 0) +
        (product.isStaple ? 10 : 0);
  }

  if (!textMatch) return null;
  final exactLabel = searchable.any((value) => value == normalized);
  final hierarchyMatch = normalizeIdentityText(hierarchy.path).contains(normalized);
  return (exactLabel ? 1_000 : hierarchyMatch ? 700 : 500) +
      (product.isFavorite ? 20 : 0) +
      (product.isStaple ? 10 : 0);
}
