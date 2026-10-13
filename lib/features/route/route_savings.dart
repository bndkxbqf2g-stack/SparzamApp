import '../../models/route_plan.dart';
import 'route_price_resolver.dart';

/// Returns the substantiated savings from active offers used by [plan].
///
/// The resolver is called again for the assigned store and list quantity, so
/// the figure follows the same branch, validity and product-compatibility rules
/// as the route itself. Missing, expired or unproven offers contribute nothing.
double routeOfferSavings(RoutePlan plan, RoutePriceResolver prices) {
  return plan.assignments.entries.fold<double>(
    0,
    (storeTotal, entry) => storeTotal + entry.value.fold<double>(
      0,
      (itemTotal, item) {
        final quote = prices.quote(entry.key, item);
        if (quote == null ||
            !quote.usesOffer ||
            !quote.savings.isFinite ||
            quote.savings <= 0) {
          return itemTotal;
        }
        return itemTotal + quote.savings;
      },
    ),
  );
}
