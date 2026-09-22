import '../../models/product.dart';
import '../../models/recent_purchase.dart';
import '../../models/replenishment_suggestion.dart';

List<Product> productsForReplenishment(ReplenishmentSuggestion suggestion) =>
    List<Product>.filled(
      suggestion.suggestedQuantity,
      suggestion.product,
      growable: false,
    );

List<Product> productsForRecentPurchase(RecentPurchase purchase) =>
    List<Product>.filled(
      purchase.averageQuantity.round().clamp(1, 100),
      purchase.toProduct(),
      growable: false,
    );
