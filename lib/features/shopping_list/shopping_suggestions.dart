import '../../data/products.dart';
import '../../models/product.dart';
import '../../models/recent_purchase.dart';
import '../catalog/product_identity.dart';

List<Product> buildSuggestions({
  required String query,
  required List<RecentPurchase> knownItems,
  required List<RecentPurchase> recentPurchases,
  required Map<String, String> preferredProductByGroup,
  List<Product> catalogProducts = products,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return const <Product>[];

  final learnedMatches = knownItems
      .map((item) => item.toProduct())
      .where((product) => product.name.toLowerCase().contains(normalized));
  final queryIdentity = identifyProduct(query);
  final catalogMatches = catalogProducts.where((product) {
    final values = [product.name, product.group, ...product.aliases];
    final textMatch =
        values.any((value) => value.toLowerCase().contains(normalized));
    if (!queryIdentity.isKnown) return textMatch;

    final identities = [product.name, ...product.aliases]
        .map(identifyProduct)
        .where((identity) => identity.isKnown)
        .toList();
    if (identities.isNotEmpty) {
      return identities.any(
        (candidate) => compatibleProductIdentity(queryIdentity, candidate),
      );
    }
    return textMatch;
  });

  final seen = <String>{};
  final matches = <Product>[...catalogMatches, ...learnedMatches]
      .where((product) => seen.add(product.id))
      .toList();

  matches.sort((a, b) {
    final aLearned = knownItems.any((item) => item.id == a.id);
    final bLearned = knownItems.any((item) => item.id == b.id);
    if (aLearned != bLearned) return aLearned ? -1 : 1;

    final aPurchase = recentPurchases.where((item) => item.id == a.id).firstOrNull;
    final bPurchase = recentPurchases.where((item) => item.id == b.id).firstOrNull;
    if (aPurchase != null || bPurchase != null) {
      if (aPurchase == null) return 1;
      if (bPurchase == null) return -1;
      if (aPurchase.purchaseCount != bPurchase.purchaseCount) {
        return bPurchase.purchaseCount.compareTo(aPurchase.purchaseCount);
      }
    }

    final aPreferred = preferredProductByGroup[a.group] == a.id;
    final bPreferred = preferredProductByGroup[b.group] == b.id;
    if (aPreferred != bPreferred) return aPreferred ? -1 : 1;
    if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
    return a.name.compareTo(b.name);
  });

  return matches;
}

List<Product> buildQuickProducts(
  Map<String, String> preferredProductByGroup, {
  List<Product> catalogProducts = products,
}) {
  final preferredIds = preferredProductByGroup.values.toSet();
  final seen = <String>{};
  return <Product>[
    ...catalogProducts.where((p) => preferredIds.contains(p.id)),
    ...catalogProducts.where((p) => p.isFavorite),
  ].where((p) => seen.add(p.id)).take(5).toList();
}
