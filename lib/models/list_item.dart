import 'product.dart';

class ListItem {
  ListItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;
}
