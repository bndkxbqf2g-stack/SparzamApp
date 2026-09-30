import '../../models/offer.dart';
import '../../models/product.dart';
import '../catalog/product_identity.dart';
import 'offer_import.dart';
import 'offer_filter.dart';
import 'prospect_product_match.dart';

/// Keeps every verified current leaflet item discoverable from the shopping
/// list, even when its product identity is not yet in the local catalog.
///
/// A fallback product is based on the exact retailer label. It does not add
/// aliases or merge similar labels across retailers. The user can select it
/// from search and thereby save that exact product to the local catalog.
List<ProspectOfferProduct> prospectOfferProducts({
  required Iterable<OfferImportRecord> records,
  required Iterable<Product> catalogProducts,
  DateTime? now,
}) {
  final catalog = catalogProducts.toList(growable: false);
  final result = <String, ProspectOfferProduct>{};
  for (final record in records) {
    if (!_isUsableRecord(record, now: now)) continue;
    final product = productForProspectOffer(record, catalog);
    final offer = _offerForProduct(record, product, now: now);
    if (offer == null) continue;
    final key = '${offer.storeName}|${offer.id}';
    result.putIfAbsent(key, () => ProspectOfferProduct(product, offer));
  }
  return result.values.toList(growable: false);
}

Product productForProspectOffer(
  OfferImportRecord record,
  Iterable<Product> catalogProducts,
) {
  return exactProspectProduct(record.productLabel, catalogProducts) ??
      _offerBackedProduct(record);
}

class ProspectOfferProduct {
  const ProspectOfferProduct(this.product, this.offer);

  final Product product;
  final Offer offer;
}

bool _isUsableRecord(OfferImportRecord record, {DateTime? now}) {
  if (record.productLabel.trim().isEmpty ||
      record.storeName.trim().isEmpty ||
      !record.offerPrice.isFinite ||
      record.offerPrice <= 0 ||
      (record.originalPrice != null &&
          (!record.originalPrice!.isFinite ||
              record.originalPrice! < record.offerPrice)) ||
      (record.validFrom != null &&
          record.validUntil.isBefore(record.validFrom!)) ||
      (record.source != 'manual' &&
          record.proofRef?.trim().isNotEmpty != true)) {
    return false;
  }
  return isOfferDateRangeActive(
    validFrom: record.validFrom,
    validUntil: record.validUntil,
    now: now,
  );
}

Product _offerBackedProduct(OfferImportRecord record) {
  final label = record.productLabel.trim();
  final package = RegExp(
    r'\b\d+(?:[,.]\d+)?\s?(?:kg|g|l|ml|stk\.?|stück|x\s*\d+)\b',
    caseSensitive: false,
  ).firstMatch(label)?.group(0);
  final hasEachUnit = RegExp(
    r'\b(?:stück|stk\.?|je stück)\b',
    caseSensitive: false,
  ).hasMatch(label);
  return Product(
    id: 'prospect|${normalizeIdentityText(label)}',
    name: label,
    unit: package ?? (hasEachUnit ? 'Stück' : 'Packung'),
    group: 'prospekt',
    imageUrl: record.imageUrl,
  );
}

Offer? _offerForProduct(
  OfferImportRecord record,
  Product product, {
  DateTime? now,
}) {
  if (!_isUsableRecord(record, now: now)) return null;
  final originalPrice = record.originalPrice ?? record.offerPrice;
  return Offer(
    id: 'import|${record.source}|${record.sourceId}|${product.id}',
    productId: product.id,
    storeName: record.storeName,
    originalPrice: originalPrice,
    originalPriceVerified: record.originalPrice != null,
    offerPrice: record.offerPrice,
    validFrom: record.validFrom,
    validUntil: record.validUntil,
    source: record.source,
    proofRef: record.proofRef,
    imageUrl: record.imageUrl,
  );
}
