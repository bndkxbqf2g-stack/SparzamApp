import '../features/catalog/unit_price.dart';
import '../models/market_price.dart';
import '../models/offer.dart';
import '../models/product.dart';
import 'quantity_normalizer.dart';

/// Checks an explicit observed package against the requested product.
///
/// A missing quantity is legacy evidence and remains readable. Once a source
/// declares an amount, an unknown or incompatible product package must stay a
/// data gap instead of becoming a route price.
bool quantityMatchesProduct({
  required double? quantity,
  required String? unit,
  required Product product,
}) {
  if (quantity == null) return true;
  final expected = productQuantity(product);
  final observed = normalizeQuantity(quantity, unit);
  if (expected == null || observed == null) return false;
  final expectedNormalized = normalizeQuantity(expected.amount, expected.unit);
  if (expectedNormalized == null ||
      expectedNormalized.dimension != observed.dimension) {
    return false;
  }
  return (expectedNormalized.amount - observed.amount).abs() < 0.000001;
}

bool marketPriceMatchesProduct(MarketPrice price, Product product) =>
    quantityMatchesProduct(
      quantity: price.quantity,
      unit: price.unit,
      product: product,
    );

/// Imported offers may carry a package basis after the feed-to-Offer step.
/// Missing legacy metadata remains readable; an explicit incompatible package
/// must stay out of price ranking and route planning.
bool offerMatchesProduct(Offer offer, Product product) =>
    quantityMatchesProduct(
      quantity: offer.packageAmount,
      unit: offer.packageUnit,
      product: product,
    );
