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
        'cl' => amount / 100,
        'l' => amount,
        'st' => amount,
        _ => null,
      };

  String? get baseUnit => switch (unit) {
        'g' || 'kg' => 'kg',
        'ml' || 'cl' || 'l' => 'l',
        'st' => 'Stk',
        _ => null,
      };
}

ProductQuantity? productQuantity(Product product) {
  final explicitAmount = product.packageAmount;
  final explicitUnit = _canonicalUnit(product.packageUnit);
  if (explicitAmount != null && explicitAmount > 0 && explicitUnit != null) {
    return ProductQuantity(amount: explicitAmount, unit: explicitUnit);
  }
  return _productUnitText(product.unit);
}

ProductQuantity? _productUnitText(String raw) {
  final text = raw.trim().toLowerCase().replaceAll(',', '.');
  if (text.isEmpty || text.contains('/') ||
      RegExp(r'\d+(?:\.\d+)?\s*(?:-|–)\s*\d+').hasMatch(text)) {
    return null;
  }

  final countPack = RegExp(
    r'^\s*(\d+)\s*er(?:\s*[- ]?\s*'
    r'(?:schale|pack(?:ung)?|becher|dose|flasche))?(?:\s|$)',
  ).firstMatch(text);
  if (countPack != null) {
    final count = double.tryParse(countPack.group(1)!);
    if (count != null && count > 0) {
      return ProductQuantity(amount: count, unit: 'st');
    }
    return null;
  }

  final multi = RegExp(
    r'^\s*(\d+)\s*[x×]\s*(\d+(?:\.\d+)?)\s*'
    r'(kg|g|ml|cl|l|stk\.?|stück|st)(?:\s|$)',
  ).firstMatch(text);
  if (multi != null) {
    final count = double.tryParse(multi.group(1)!);
    final amount = double.tryParse(multi.group(2)!);
    final unit = _canonicalUnit(multi.group(3));
    if (count != null && amount != null && count > 0 && amount > 0 && unit != null) {
      return ProductQuantity(amount: count * amount, unit: unit);
    }
    return null;
  }

  final single = RegExp(
    r'^\s*(\d+(?:\.\d+)?)\s*'
    r'(kg|g|ml|cl|l|stk\.?|stück|st)(?:\s|$)',
  ).firstMatch(text);
  if (single == null) return null;
  final amount = double.tryParse(single.group(1)!);
  final unit = _canonicalUnit(single.group(2));
  if (amount == null || amount <= 0 || unit == null) return null;
  return ProductQuantity(amount: amount, unit: unit);
}

String? _canonicalUnit(String? raw) {
  final unit = raw?.trim().toLowerCase().replaceAll('.', '');
  return switch (unit) {
    'g' || 'gramm' || 'gram' => 'g',
    'kg' || 'kilogramm' || 'kilogram' => 'kg',
    'ml' || 'milliliter' || 'millilitre' => 'ml',
    'cl' || 'centiliter' || 'centilitre' => 'cl',
    'l' || 'liter' || 'litre' => 'l',
    'st' || 'stk' || 'stück' || 'stueck' => 'st',
    _ => null,
  };
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
