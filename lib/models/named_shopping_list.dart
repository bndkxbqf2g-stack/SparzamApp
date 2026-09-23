import 'list_item.dart';
import 'product.dart';

class NamedShoppingList {
  const NamedShoppingList({
    required this.id,
    required this.name,
    required this.items,
  });

  final String id;
  final String name;
  final List<ListItem> items;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items
            .map((item) => {
                  'product': item.product.toJson(),
                  'quantity': item.quantity,
                })
            .toList(),
      };

  factory NamedShoppingList.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final name = (json['name'] as String?)?.trim() ?? '';
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Ungültige Einkaufsliste');
    }
    final items = <ListItem>[];
    for (final value in json['items'] as List<dynamic>? ?? const []) {
      final item = value as Map<String, dynamic>;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      if (quantity <= 0) continue;
      items.add(ListItem(
        product: Product.fromJson(item['product'] as Map<String, dynamic>),
        quantity: quantity,
      ));
    }
    return NamedShoppingList(id: id, name: name, items: items);
  }
}
