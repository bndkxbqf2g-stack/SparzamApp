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
  final packaging = _prospectPackaging(label);
  final hasEachUnit = RegExp(
    r'\b(?:stück|stk\.?|je stück)\b',
    caseSensitive: false,
  ).hasMatch(label);
  return Product(
    id: 'prospect|${normalizeIdentityText(label)}',
    name: label,
    unit: packaging?.display ?? (hasEachUnit ? 'Stück' : 'Packung'),
    group: 'prospekt',
    packageAmount: packaging?.amount,
    packageUnit: packaging?.unit,
    imageUrl: record.imageUrl,
  );
}

({double amount, String display, String unit})? _prospectPackaging(
  String label,
) {
  final multi = RegExp(
    r'\b(\d+)\s*[x×]\s*(\d+(?:[,.]\d+)?)\s*-?\s*'
    r'(kg|g|ml|l|stk\.?|stück|st)\b',
    caseSensitive: false,
  ).firstMatch(label);
  if (multi != null) {
    final count = int.tryParse(multi.group(1)!);
    final amountEach = double.tryParse(multi.group(2)!.replaceAll(',', '.'));
    final unit = _normalizedProspectUnit(multi.group(3)!);
    if (count != null && amountEach != null && unit != null) {
      return (
        amount: count * amountEach,
        display: '$count x ${_displayNumber(amountEach)} $unit',
        unit: unit,
      );
    }
  }

  final single = RegExp(
    r'\b(\d+(?:[,.]\d+)?)\s*-?\s*(kg|g|ml|l|stk\.?|stück|st)\b',
    caseSensitive: false,
  ).firstMatch(label);
  if (single == null) return null;
  final amount = double.tryParse(single.group(1)!.replaceAll(',', '.'));
  final unit = _normalizedProspectUnit(single.group(2)!);
  if (amount == null || unit == null) return null;
  return (
    amount: amount,
    display: '${_displayNumber(amount)} $unit',
    unit: unit,
  );
}

String? _normalizedProspectUnit(String raw) {
  final normalized = raw.toLowerCase().replaceAll('.', '');
  return switch (normalized) {
    'kg' => 'kg',
    'g' => 'g',
    'ml' => 'ml',
    'l' => 'l',
    'stk' || 'st' || 'stück' => 'Stück',
    _ => null,
  };
}

String _displayNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString().replaceAll('.', ',');

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
