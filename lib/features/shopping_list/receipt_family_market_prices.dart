import '../../models/list_item.dart';
import '../../models/market_price.dart';
import '../../models/receipt_observation.dart';
import '../../models/price_observation.dart';
import '../catalog/product_identity.dart';
import '../route/market_price_selection.dart';
import '../../services/quantity_normalizer.dart';

/// Bridges receipt history into the common market-price pipeline.
List<MarketPrice> receiptFamilyMarketPrices({
  required Iterable<ListItem> items,
  required Iterable<ReceiptObservation> observations,
  DateTime? now,
  int maxAgeDays = 30,
}) {
  final today = now ?? DateTime.now();
  final cutoff = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: maxAgeDays));
  final result = <String, MarketPrice>{};

  for (final item in items) {
    // A recalled raw receipt label has no confirmed pack/variant identity.
    // It may be added to the list, but it cannot inherit a route price.
    if (item.product.id.startsWith('receipt_suggestion_')) continue;
    final request = identifyProduct(item.product.name);
    final normalizedRequest = normalizeIdentityText(item.product.name);
    if (!request.isKnown && normalizedRequest.isEmpty) continue;

    for (final observation in observations) {
      if (observation.observedAt.isAfter(today)) continue;
      if (observation.observedAt.isBefore(cutoff)) continue;
      if (observation.productId?.isNotEmpty == true &&
          !observation.identityConfirmed) {
        continue;
      }
      final candidate = identifyProduct(observation.rawLabel);
      final confirmedProduct = observation.identityConfirmed &&
          observation.productId?.trim() == item.product.id;
      // Receipt imports retain the inferred family independently of the raw
      // label. Use it only when the label resolver has no identity at all;
      // this keeps an explicit "Tomatenmark" label from being widened into
      // the fresh-tomato family by a stale legacy family key.
      final candidateForMatching = candidate.isKnown
          ? candidate
          : _familyIdentityFallback(observation.familyKey, candidate);
      final normalizedCandidate = normalizeIdentityText(observation.rawLabel);
      final exact =
          normalizedRequest == normalizedCandidate ||
          item.product.aliases.any(
            (alias) => normalizeIdentityText(alias) == normalizedCandidate,
          );
      final compatible =
          request.isKnown &&
          compatibleProductIdentity(request, candidateForMatching);
      // A confirmed concrete product assignment is stronger than receipt
      // text. It is still checked against the requested package below.
      if (!confirmedProduct && !exact && !compatible) continue;

      final price = _comparablePrice(item, observation);
      if (price == null || !price.isFinite || price <= 0) continue;
      final key = '${observation.storeName}|${item.product.id}';
      final marketPrice = MarketPrice(
        productId: item.product.id,
        storeName: observation.storeName,
        price: price,
        updatedAt: observation.observedAt,
        source: MarketPriceSource.receipt,
        discounted: observation.discounted,
        kind: observation.discounted
            ? PriceObservationKind.offer
            : PriceObservationKind.regular,
        proofRef:
            'receipt:${observation.receiptFingerprint}|line:${observation.rowLine}',
        quantity: item.product.packageAmount,
        unit: item.product.packageUnit,
        unitPrice: item.product.packageAmount == null ||
                item.product.packageUnit == null
            ? null
            : normalizedUnitPrice(
                price: price,
                amount: item.product.packageAmount,
                unit: item.product.packageUnit,
              ),
      );
      final previous = result[key];
      if (previous == null ||
          _isBetterFamilyPrice(marketPrice, previous, today)) {
        result[key] = marketPrice;
      }
    }
  }
  return result.values.toList();
}

ProductIdentity _familyIdentityFallback(
  String familyKey,
  ProductIdentity unresolved,
) {
  final family = familyKey.trim();
  if (family.isEmpty) return unresolved;

  // Canonical family keys normally resolve back through the same hierarchy
  // (including keys containing German umlauts). Keep the raw key as a final
  // evidence-preserving fallback for older or newly introduced families.
  final resolvedFamily = identifyProduct(family);
  return resolvedFamily.isKnown
      ? resolvedFamily
      : ProductIdentity(familyKey: family);
}

bool _isBetterFamilyPrice(
  MarketPrice candidate,
  MarketPrice previous,
  DateTime now,
) =>
    compareMarketPriceEvidence(candidate, previous, now) < 0;

double? _comparablePrice(ListItem item, ReceiptObservation observation) {
  final packageAmount = item.product.packageAmount;
  final packageUnit = item.product.packageUnit;
  if (packageAmount == null || packageUnit == null) {
    // A normal single receipt row has no explicit quantity but still carries
    // the parser's default "Stück" unit. It is a valid observed package price.
    if (observation.quantity == null) {
      return observation.totalPrice;
    }
    // "2 x 2,49" describes two identical purchased packages. For a generic
    // shopping-list item compare one package, not the summed receipt line.
    if (observation.quantityUnit == 'Stück' &&
        observation.unitPrice != null &&
        observation.unitPrice!.isFinite &&
        observation.unitPrice! > 0) {
      return observation.unitPrice;
    }
    // Weight/volume observations cannot be projected to a generic product
    // without a requested package basis.
    return null;
  }
  final receiptAmount = observation.quantity?.toDouble();
  final receiptUnit = observation.quantityUnit;
  if (receiptAmount == null || receiptUnit.isEmpty) return null;
  final wanted = normalizeQuantity(packageAmount, packageUnit);
  final seen = normalizeQuantity(receiptAmount, receiptUnit);
  if (wanted == null || seen == null || wanted.dimension != seen.dimension) {
    return null;
  }
  final perBase = normalizedUnitPrice(
    price: observation.totalPrice,
    amount: receiptAmount,
    unit: receiptUnit,
  );
  if (perBase == null) return null;
  return perBase * wanted.amount;
}
