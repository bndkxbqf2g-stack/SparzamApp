import 'product.dart';

enum ReplenishmentUrgency { overdue, dueSoon }

class ReplenishmentSuggestion {
  const ReplenishmentSuggestion({
    required this.product,
    required this.purchaseCount,
    required this.averageQuantity,
    required this.intervalDays,
    required this.lastPurchasedAt,
    required this.dueAt,
    required this.daysUntilDue,
    required this.urgency,
    this.fromPurchaseHistory = true,
    this.fromConfirmedReceipts = false,
  });

  final Product product;
  final int purchaseCount;
  final double averageQuantity;
  final int intervalDays;
  final DateTime lastPurchasedAt;
  final DateTime dueAt;
  final int daysUntilDue;
  final ReplenishmentUrgency urgency;
  final bool fromPurchaseHistory;
  final bool fromConfirmedReceipts;

  int get suggestedQuantity => averageQuantity.round().clamp(1, 99);

  String get evidenceLabel {
    if (fromPurchaseHistory && fromConfirmedReceipts) {
      return 'Kaufhistorie + bestätigte Bons';
    }
    if (fromConfirmedReceipts) return 'bestätigte Bons';
    return 'Kaufhistorie';
  }

  String get timingLabel {
    if (daysUntilDue < 0) {
      final days = -daysUntilDue;
      return days == 1 ? 'seit gestern fällig' : 'seit $days Tagen fällig';
    }
    if (daysUntilDue == 0) return 'heute wieder fällig';
    if (daysUntilDue == 1) return 'voraussichtlich morgen';
    return 'voraussichtlich in $daysUntilDue Tagen';
  }
}
