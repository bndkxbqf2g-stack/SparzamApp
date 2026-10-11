import '../../models/list_item.dart';
import '../../models/product.dart';
import '../catalog/product_identity.dart';

/// Returns whether a price gap needs a concrete product choice before a
/// market price can be useful for route planning.
///
/// A generic request such as "Milch" and a user-created product with a known
/// family both need an explicit variant choice. Unknown free text remains in
/// the manual price editor because there is no safe identity to broaden.
bool shouldResolvePriceGapByProductSelection(Product product) {
  final identity = identifyProduct(product.name);
  return identity.isKnown &&
      (identity.isGeneric || product.id.startsWith('custom_'));
}

/// Replaces one unresolved list position with the products selected by the
/// user. The source item is never mutated, and an empty or unknown selection
/// leaves the list unchanged.
List<ListItem>? replacePriceGapItem({
  required List<ListItem> items,
  required String sourceProductId,
  required List<Product> selectedProducts,
}) {
  if (selectedProducts.isEmpty) return null;
  final index = items.indexWhere(
    (item) => item.product.id == sourceProductId,
  );
  if (index < 0) return null;

  final source = items[index];
  final replacement = selectedProducts
      .map(
        (product) => ListItem(
          product: product,
          quantity: source.quantity,
          note: source.note.isEmpty
              ? 'Aus Auswahl aus „${source.product.name}“'
              : source.note,
          checked: source.checked,
        ),
      )
      .toList(growable: false);
  return [
    ...items.take(index),
    ...replacement,
    ...items.skip(index + 1),
  ];
}
