enum QuantityDimension { mass, volume, count }

class NormalizedQuantity {
  const NormalizedQuantity({
    required this.amount,
    required this.dimension,
    required this.baseUnit,
  });

  final double amount;
  final QuantityDimension dimension;
  final String baseUnit;
}

NormalizedQuantity? normalizeQuantity(double? amount, String? unit) {
  if (amount == null || !amount.isFinite || amount <= 0) return null;
  final normalized = _normalizeUnit(unit);
  return switch (normalized) {
    'g' || 'gram' || 'grams' || 'gramm' => NormalizedQuantity(
        amount: amount / 1000,
        dimension: QuantityDimension.mass,
        baseUnit: 'kg',
      ),
    'kg' || 'kilogram' || 'kilograms' || 'kilogramm' => NormalizedQuantity(
        amount: amount,
        dimension: QuantityDimension.mass,
        baseUnit: 'kg',
      ),
    'ml' ||
    'milliliter' ||
    'millilitre' ||
    'milliliters' ||
    'millilitres' => NormalizedQuantity(
        amount: amount / 1000,
        dimension: QuantityDimension.volume,
        baseUnit: 'l',
      ),
    'l' || 'liter' || 'litre' || 'liters' || 'litres' => NormalizedQuantity(
        amount: amount,
        dimension: QuantityDimension.volume,
        baseUnit: 'l',
      ),
    'st' ||
    'stk' ||
    'stück' ||
    'stueck' ||
    'pc' ||
    'pcs' ||
    'piece' ||
    'pieces' => NormalizedQuantity(
        amount: amount,
        dimension: QuantityDimension.count,
        baseUnit: 'Stk',
      ),
    _ => null,
  };
}

String? _normalizeUnit(String? unit) => unit
    ?.trim()
    .toLowerCase()
    .replaceAll('.', '')
    .replaceAll(RegExp(r'\s+'), ' ');

bool quantitiesComparable({
  required double? leftAmount,
  required String? leftUnit,
  required double? rightAmount,
  required String? rightUnit,
}) {
  final left = normalizeQuantity(leftAmount, leftUnit);
  final right = normalizeQuantity(rightAmount, rightUnit);
  return left != null && right != null && left.dimension == right.dimension;
}

double? normalizedUnitPrice({
  required double price,
  required double? amount,
  required String? unit,
}) {
  if (!price.isFinite || price <= 0) return null;
  final quantity = normalizeQuantity(amount, unit);
  if (quantity == null) return null;
  return price / quantity.amount;
}
