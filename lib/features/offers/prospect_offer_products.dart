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
  return exactProspectProduct(
        record.productLabel,
        catalogProducts,
        packageSize: record.packageSize,
      ) ??
      _offerBackedProduct(record);
}

/// Returns the exact catalog identity or a safe, exact-label fallback for a
/// verified current prospect offer. Ambiguous, invalid, or unproven records
/// stay unavailable instead of being added under the wrong product.
Product? addableProductForProspectOffer(
  OfferImportRecord record,
  Iterable<Product> catalogProducts,
) {
  if (!_hasVerifiedOfferEvidence(record)) return null;
  final resolution = resolveOfferImport(record, catalogProducts);
  if (resolution.product != null) return resolution.product;
  if (resolution.reason != 'unknown_identity') return null;
  return productForProspectOffer(record, catalogProducts);
}

bool _hasVerifiedOfferEvidence(OfferImportRecord record) {
  final original = record.originalPrice;
  return record.productLabel.trim().isNotEmpty &&
      record.storeName.trim().isNotEmpty &&
      !record.regionalOnly &&
      hasExactOfferRecordBranch(record) &&
      record.offerPrice.isFinite &&
      record.offerPrice > 0 &&
      (original == null ||
          (original.isFinite &&
              original > 0 &&
              record.offerPrice <= original)) &&
      (record.validFrom == null ||
          !record.validUntil.isBefore(record.validFrom!)) &&
      (record.source == 'manual' ||
          hasTrustedOfferProofReference(record.proofRef));
}

class ProspectOfferProduct {
  const ProspectOfferProduct(this.product, this.offer);

  final Product product;
  final Offer offer;
}

/// Keeps source-backed offers attached to their exact prospect product,
/// including labels that are not in the local catalog yet. The caller may
/// still require an explicit product selection before adding the item to a
/// shopping list; no family identity is inferred here.
List<Offer> offersFromProspectProducts(
  Iterable<ProspectOfferProduct> entries,
) => entries.map((entry) => entry.offer).toList(growable: false);

bool _isUsableRecord(OfferImportRecord record, {DateTime? now}) {
  if (record.productLabel.trim().isEmpty ||
      record.storeName.trim().isEmpty ||
      record.regionalOnly ||
      !hasExactOfferRecordBranch(record) ||
      !record.offerPrice.isFinite ||
      record.offerPrice <= 0 ||
      (record.originalPrice != null &&
          (!record.originalPrice!.isFinite ||
              record.originalPrice! < record.offerPrice)) ||
      (record.validFrom != null &&
          record.validUntil.isBefore(record.validFrom!)) ||
      (record.source != 'manual' &&
          !hasTrustedOfferProofReference(record.proofRef))) {
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
  final packaging = _prospectPackaging(label, record.packageSize);
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

ProspectPackage? _offerPackage(OfferImportRecord record, Product product) {
  final fromRecord = prospectPackage(record.packageSize ?? record.productLabel);
  if (fromRecord != null) return fromRecord;
  if (product.packageAmount != null && product.packageUnit != null) {
    return (amount: product.packageAmount!, unit: product.packageUnit!);
  }
  return prospectPackage(product.unit);
}

({double amount, String display, String unit})? _prospectPackaging(
  String label, [
  String? packageSize,
]) {
  final packageText = packageSize?.trim().isNotEmpty == true
      ? packageSize!.trim()
      : label;
  final text = packageText.toLowerCase();
  if (RegExp(
    r'\d+(?:[,.]\d+)?\s*(?:kg|g|ml|cl|l)\s*(?:/|-|–)\s*'
    r'\d+(?:[,.]\d+)?\s*(?:kg|g|ml|cl|l)?\b',
  ).hasMatch(text) || RegExp(
    r'\d+(?:[,.]\d+)?\s*/\s*\d+(?:[,.]\d+)?\s*'
    r'(?:kg|g|ml|cl)\b',
  ).hasMatch(text)) {
    return null;
  }
  final multi = RegExp(
    r'\b(\d+)\s*[x×]\s*(\d+(?:[,.]\d+)?)\s*-?\s*'
    r'(kg|g|ml|cl|l|stk\.?|stück|st)\b',
    caseSensitive: false,
  ).firstMatch(packageText);
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

  final countPack = RegExp(
    r'\b(\d+)\s*er\s*[- ]?(?:schale|pack(?:ung)?|becher|dose|flasche)\b',
    caseSensitive: false,
  ).firstMatch(packageText);
  if (countPack != null) {
    final count = int.tryParse(countPack.group(1)!);
    if (count != null && count > 0) {
      return (
        amount: count.toDouble(),
        display: '$count Stück',
        unit: 'Stück',
      );
    }
  }

  final single = RegExp(
    r'\b(\d+(?:[,.]\d+)?)\s*-?\s*(kg|g|ml|cl|l|stk\.?|stück|st)\b',
    caseSensitive: false,
  ).firstMatch(packageText);
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
    'cl' => 'cl',
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
  final package = _offerPackage(record, product);
  final packagePrice = package == null
      ? null
      : normalizedUnitPrice(
          price: record.offerPrice,
          amount: package.amount,
          unit: package.unit,
        );
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
    sourceAdapter: record.sourceAdapter,
    capturedAt: record.capturedAt,
    proofRef: record.proofRef,
    imageUrl: record.imageUrl,
    packageAmount: package?.amount,
    packageUnit: package?.unit,
    unitPrice: packagePrice,
    locationId: record.branchId,
    region: record.location,
    address: record.address,
  );
}

