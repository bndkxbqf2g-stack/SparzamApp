import '../../models/product.dart';

class ProductQuantity {
  const ProductQuantity({
    required this.amount,
    required this.unit,
  });

  final double amount;
  final String unit;

  double? get baseAmount => switch (unit) {
        'g' => amount / 1000,
        'kg' => amount,
        'ml' => amount / 1000,
        'l' => amount,
        'st' => amount,
        _ => null,
      };

  String? get baseUnit => switch (unit) {
        'g' || 'kg' => 'kg',
        'ml' || 'l' => 'l',
        'st' => 'Stk',
        _ => null,
      };
}

ProductQuantity? productQuantity(Product product) {
  final amount = product.packageAmount;
  final unit = product.packageUnit?.toLowerCase();
  if (amount == null || amount <= 0 || unit == null || unit.isEmpty) {
    return null;
  }
  return ProductQuantity(amount: amount, unit: unit);
}

double? baseUnitPrice(Product product, double packagePrice) {
  final quantity = productQuantity(product);
  final baseAmount = quantity?.baseAmount;
  if (baseAmount == null || baseAmount <= 0) return null;
  return packagePrice / baseAmount;
}

String? baseUnitPriceLabel(Product product, double packagePrice) {
  final quantity = productQuantity(product);
  final price = baseUnitPrice(product, packagePrice);
  final unit = quantity?.baseUnit;
  if (price == null || unit == null) return null;
  return '${price.toStringAsFixed(2)} €/$unit';
}
