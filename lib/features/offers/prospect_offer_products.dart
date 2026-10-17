import '../../models/offer.dart';
import '../../models/product.dart';
import '../../services/quantity_normalizer.dart';
import '../../services/barcode_normalizer.dart';
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
  final catalogIndex = OfferImportCatalogIndex(catalog);
  final result = <String, ProspectOfferProduct>{};
  for (final record in records) {
    if (!_isUsableRecord(record, now: now)) continue;
    final product = productForProspectOffer(
      record,
      catalog,
      catalogIndex: catalogIndex,
    );
    final offer = _offerForProduct(record, product, now: now);
    if (offer == null) continue;
    final key = prospectOfferSnapshotKey(offer);
    result.putIfAbsent(key, () => ProspectOfferProduct(product, offer));
  }
  return result.values.toList(growable: false);
}

Product productForProspectOffer(
  OfferImportRecord record,
  Iterable<Product> catalogProducts, {
  OfferImportCatalogIndex? catalogIndex,
}) {
  final sourceEanText = record.ean?.trim() ?? '';
  final sourceEan = sourceEanText.isEmpty
      ? null
      : normalizeBarcode(sourceEanText);
  if (sourceEan != null) {
    // Do not let a conflicting source code fall back to a similarly named
    // catalog product. It remains an exact-label review item instead.
    final exactEan = catalogIndex == null
        ? exactProspectProductByEan(record.ean, catalogProducts)
        : _exactIndexedProductByEan(catalogIndex, sourceEan);
    return exactEan ?? _offerBackedProduct(record);
  }
  final indexedNames =
      catalogIndex?.byName(normalizeIdentityText(record.productLabel));
  final exactProduct = exactProspectProduct(
    record.productLabel,
    indexedNames == null || indexedNames.isEmpty
        ? catalogProducts
        : indexedNames,
    packageSize: record.packageSize,
  );
  // Package-suffixed labels may intentionally match a catalog core name, so
  // retry the full snapshot only when the narrow exact-name bucket did not
  // resolve the package basis.
  final resolved = exactProduct ??
      (indexedNames == null || indexedNames.isEmpty
          ? null
          : exactProspectProduct(
              record.productLabel,
              catalogProducts,
              packageSize: record.packageSize,
            ));
  return resolved ?? _offerBackedProduct(record);
}

Product? _exactIndexedProductByEan(
  OfferImportCatalogIndex index,
  String sourceEan,
) {
  final matches = index.byEan(sourceEan).toList(growable: false);
  return matches.length == 1 ? matches.single : null;
}

/// Returns the exact catalog identity or a safe, exact-label fallback for a
/// verified current prospect offer. Ambiguous, invalid, or unproven records
/// stay unavailable instead of being added under the wrong product.
Product? addableProductForProspectOffer(
  OfferImportRecord record,
  Iterable<Product> catalogProducts, {
  OfferImportCatalogIndex? catalogIndex,
}) {
  if (!_hasVerifiedOfferEvidence(record)) return null;
  final resolution = resolveOfferImport(
    record,
    catalogProducts,
    catalogIndex: catalogIndex,
  );
  if (resolution.product != null) return resolution.product;
  if (resolution.reason != 'unknown_identity') return null;
  return productForProspectOffer(
    record,
    catalogProducts,
    catalogIndex: catalogIndex,
  );
}

/// Returns an exact-label product for an explicit user review when a
/// current, branch-specific offer cannot be mapped to one catalog identity.
///
/// The returned product is list-only until the caller confirms it. This path
/// never creates an Offer or route price from an ambiguous identity.
Product? manualProductForProspectOffer(OfferImportRecord record) {
  if (!_hasVerifiedOfferEvidence(record)) return null;
  return _offerBackedProduct(record);
}

/// Returns a product that may be added to the shopping list when a current
/// prospect was found only at publisher/region level. The product deliberately
/// remains list-only: without an exact branch it must not create an [Offer],
/// [MarketPrice], or route price.
Product? listOnlyProductForRegionalProspectOffer(
  OfferImportRecord record,
  Iterable<Product> catalogProducts, {
  OfferImportCatalogIndex? catalogIndex,
}) {
  if (!record.regionalOnly ||
      !_hasVerifiedOfferEvidence(record, requireExactBranch: false)) {
    return null;
  }
  return productForProspectOffer(
    record,
    catalogProducts,
    catalogIndex: catalogIndex,
  );
}

bool _hasVerifiedOfferEvidence(
  OfferImportRecord record, {
  bool requireExactBranch = true,
}) {
  final original = record.originalPrice;
  return record.productLabel.trim().isNotEmpty &&
      record.storeName.trim().isNotEmpty &&
      (!requireExactBranch ||
          (!record.regionalOnly && hasExactOfferRecordBranch(record))) &&
      record.offerPrice.isFinite &&
      record.offerPrice > 0 &&
      (original == null ||
          (original.isFinite &&
              original > 0 &&
              record.offerPrice <= original)) &&
      (record.ean == null ||
          record.ean!.trim().isEmpty ||
          normalizeBarcode(record.ean!.trim()) != null) &&
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

/// Stable key for a transient prospect offer.
///
/// A provider's source ID is often scoped to a leaflet rather than to one
/// branch. Retain the exact store context so two same-name branches cannot
/// overwrite each other during a feed refresh.
String prospectOfferSnapshotKey(Offer offer) => [
      offer.id.trim(),
      offer.storeName.trim().toLowerCase(),
      offer.locationId?.trim().toLowerCase() ?? '',
      offer.region?.trim().toLowerCase() ?? '',
      offer.address?.trim().toLowerCase() ?? '',
    ].join('\u001f');

/// Builds the transient offer snapshot for a validated current prospect
/// feed. Existing automatic imports are discarded so a refreshed feed cannot
/// retain expired rows, while manual/user-reviewed offers remain available.
/// The result is intentionally in-memory; callers decide separately which
/// regular price observations are persisted.
List<Offer> mergeTransientProspectOffers({
  required Iterable<Offer> existingOffers,
  required Iterable<ProspectOfferProduct> importedOffers,
}) {
  final bySnapshotKey = <String, Offer>{
    for (final offer in existingOffers)
      if (!offer.id.startsWith('import|'))
        prospectOfferSnapshotKey(offer): offer,
  };
  for (final entry in importedOffers) {
    bySnapshotKey[prospectOfferSnapshotKey(entry.offer)] = entry.offer;
  }
  return bySnapshotKey.values.toList(growable: false);
}

/// Keeps source-backed offers attached to their exact prospect product,
/// including labels that are not in the local catalog yet. The caller may
/// still require an explicit product selection before adding the item to a
/// shopping list; no family identity is inferred here.
List<Offer> offersFromProspectProducts(
  Iterable<ProspectOfferProduct> entries,
) => entries.map((entry) => entry.offer).toList(growable: false);

/// Extends the exact local catalog with the products created for verified
/// current prospect offers. Unknown labels stay isolated under their
/// prospect-specific identity, while an existing exact catalog product keeps
/// its established identity. This shared catalog is used before price
/// observations are persisted so regular prices can become routeable in the
/// same refresh that exposes the offer.
List<Product> catalogProductsWithProspectOffers({
  required Iterable<Product> catalogProducts,
  required Iterable<ProspectOfferProduct> offerProducts,
}) {
  final result = <Product>[];
  final seen = <String>{};
  for (final product in catalogProducts) {
    if (seen.add(product.id)) result.add(product);
  }
  for (final entry in offerProducts) {
    if (seen.add(entry.product.id)) result.add(entry.product);
  }
  return result;
}

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
  final canonicalSource =
      canonicalProspectSourceToken(record.source) ?? record.source;
  final package = _offerPackage(record, product);
  final packagePrice = package == null
      ? null
      : normalizedUnitPrice(
          price: record.offerPrice,
          amount: package.amount,
          unit: package.unit,
        );
  return Offer(
    id: 'import|$canonicalSource|${record.sourceId}|${product.id}',
    productId: product.id,
    storeName: record.storeName,
    originalPrice: originalPrice,
    originalPriceVerified: record.originalPrice != null,
    offerPrice: record.offerPrice,
    validFrom: record.validFrom,
    validUntil: record.validUntil,
    source: canonicalSource,
    sourceAdapter: record.sourceAdapter,
    regularPriceSource: canonicalProspectRegularPriceSource(
      record.regularPriceSource,
    ),
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


