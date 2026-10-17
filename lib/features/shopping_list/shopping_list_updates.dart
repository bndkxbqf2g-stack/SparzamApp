import '../../models/list_item.dart';
import '../../models/product.dart';

List<ListItem> addShoppingProduct(List<ListItem> items, Product product) {
  final index = items.indexWhere((item) => item.product.id == product.id);
  if (index < 0) return [...items, ListItem(product: product)];
  return [
    for (var i = 0; i < items.length; i++)
      i == index
          ? ListItem(
              product: product,
              quantity: items[i].quantity + 1,
              note: items[i].note,
              checked: items[i].checked,
            )
          : items[i],
  ];
}


/// Replaces list products with newer catalog metadata for the same exact ID.
///
/// Quantities and user-entered state stay attached to the list item. If no
/// matching product changed, the original list instance is returned so callers
/// can keep their existing snapshot caches.
List<ListItem> refreshShoppingListProducts({
  required List<ListItem> items,
  required List<Product> catalogProducts,
}) {
  final byId = <String, Product>{};
  for (final product in catalogProducts) {
    final id = product.id.trim();
    if (id.isEmpty || byId.containsKey(id)) continue;
    byId[id] = product;
  }

  var changed = false;
  final refreshed = <ListItem>[];
  for (final item in items) {
    final replacement = byId[item.product.id];
    if (replacement == null || _sameProductMetadata(item.product, replacement)) {
      refreshed.add(item);
      continue;
    }
    changed = true;
    refreshed.add(
      ListItem(
        product: replacement,
        quantity: item.quantity,
        note: item.note,
        checked: item.checked,
      ),
    );
  }
  return changed ? refreshed : items;
}

bool _sameProductMetadata(Product a, Product b) {
  if (a.id != b.id ||
      a.name != b.name ||
      a.unit != b.unit ||
      a.group != b.group ||
      a.isFavorite != b.isFavorite ||
      a.isStaple != b.isStaple ||
      a.ean != b.ean ||
      a.brand != b.brand ||
      a.packageAmount != b.packageAmount ||
      a.packageUnit != b.packageUnit ||
      a.imageUrl != b.imageUrl ||
      a.aliases.length != b.aliases.length) {
    return false;
  }
  for (var i = 0; i < a.aliases.length; i++) {
    if (a.aliases[i] != b.aliases[i]) return false;
  }
  return true;
}
