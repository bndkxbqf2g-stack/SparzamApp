import '../../models/purchase_record.dart';

class MonthlyPurchaseSummary {
  const MonthlyPurchaseSummary({
    required this.spent,
    required this.savings,
    required this.purchases,
  });

  final double spent;
  final double savings;
  final int purchases;
}

MonthlyPurchaseSummary summarizeMonth(
  List<PurchaseRecord> history, {
  DateTime? now,
}) {
  final date = now ?? DateTime.now();
  final month = history.where(
    (item) => item.createdAt.year == date.year && item.createdAt.month == date.month,
  );
  return MonthlyPurchaseSummary(
    spent: month.fold(0.0, (sum, item) => sum + item.basket),
    savings: month.fold(0.0, (sum, item) => sum + item.savings),
    purchases: month.length,
  );
}
