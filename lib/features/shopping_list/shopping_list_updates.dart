import '../../models/list_item.dart';
import '../../models/product.dart';

List<ListItem> addShoppingProduct(List<ListItem> items, Product product) {
  final index = items.indexWhere((item) => item.product.id == product.id);
  if (index < 0) return [...items, ListItem(product: product)];
  return [
    for (var i = 0; i < items.length; i++)
      i == index
          ? ListItem(product: product, quantity: items[i].quantity + 1)
          : items[i],
  ];
}
