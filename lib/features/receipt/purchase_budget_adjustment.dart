import '../../models/purchase_record.dart';

double adjustedFoodSpent({
  required double currentFoodSpent,
  required PurchaseRecord previous,
  PurchaseRecord? replacement,
  DateTime? now,
}) {
  final date = now ?? DateTime.now();
  final previousAmount = _isSameMonth(previous.createdAt, date)
      ? previous.basket
      : 0.0;
  final replacementAmount = replacement != null &&
          _isSameMonth(replacement.createdAt, date)
      ? replacement.basket
      : 0.0;

  return (currentFoodSpent - previousAmount + replacementAmount)
      .clamp(0.0, double.infinity)
      .toDouble();
}

bool _isSameMonth(DateTime value, DateTime reference) =>
    value.year == reference.year && value.month == reference.month;
