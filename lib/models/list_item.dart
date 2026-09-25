import 'product.dart';

class ListItem {
  ListItem({
    required this.product,
    this.quantity = 1,
    this.note = '',
    this.checked = false,
  });

  final Product product;
  int quantity;
  String note;
  bool checked;
}
