import '../../models/offer.dart';
import '../../models/price_observation.dart';
import '../../models/product.dart';
import '../catalog/product_identity.dart';
import 'offer_filter.dart';
import 'prospect_product_match.dart';
import '../../services/prospect_branch_resolver.dart';
import '../../services/quantity_normalizer.dart';
import '../../services/barcode_normalizer.dart';

/// Identifies what an imported prospect image actually represents.
///
/// A page image is useful evidence for an offer, but it is not a product
/// photograph. Keeping the distinction prevents the UI and later imports from
/// presenting a whole leaflet page as a precise article image.
enum ProspectImageKind {
  product,
  prospectPage,
}

class OfferImportRecord {
  const OfferImportRecord({
    required this.sourceId,
    required this.productLabel,
    required this.storeName,
    this.originalPrice,
    required this.offerPrice,
    required this.validUntil,
    this.validFrom,
    this.source = 'leaflet',
    this.proofRef,
    this.imageUrl,
    this.imageKind,
    this.ean,
    this.category,
    this.packageSize,
    this.priceByBaseUnit,
    this.regularPriceSource,
    this.sourceAdapter,
    this.regionalOnly = false,
    this.brochureId,
    this.brochurePage,
    this.publisherId,
    this.capturedAt,
    this.branchId,
    this.location,
    this.address,
  });

  final String sourceId;
  final String productLabel;
  final String storeName;
  final double? originalPrice;
  final double offerPrice;
  final DateTime validUntil;
  final DateTime? validFrom;
  final String source;
  final String? proofRef;
  final String? imageUrl;

  /// Provenance of [imageUrl]. Null keeps legacy feed rows explicit as
  /// unknown instead of guessing whether the source supplied a product photo.
  final ProspectImageKind? imageKind;

  /// Optional source-provided GTIN/EAN. It is only used for exact catalog
  /// matching; a missing or conflicting code never creates a new identity.
  final String? ean;

  /// Category supplied by the retailer feed, when the source exposes one.
  /// The UI may fall back to its conservative label classifier when absent;
  /// this field is never inferred into product identity or price evidence.
  final String? category;

  /// Optional package and base-price metadata supplied by the retailer. These
  /// fields remain source evidence; identity matching still requires the
  /// exact label and a comparable package basis.
  final String? packageSize;
  final String? priceByBaseUnit;

  /// Exact source field that supplied an explicitly stated regular/crossed-out
  /// price. It is optional for legacy records; new adapters should preserve it
  /// so automatic regular-price persistence remains auditable.
  final String? regularPriceSource;

  /// Optional adapter identity and regional/leaflet context. A regional-only
  /// result is diagnostic evidence and must not be treated as an exact branch
  /// price by route planning.
  final String? sourceAdapter;
  final bool regionalOnly;
  final String? brochureId;
  final int? brochurePage;
  final String? publisherId;

  /// Time at which this individual source record was captured. Older feeds
  /// may only carry the feed-level timestamp.
  final DateTime? capturedAt;

  /// Source-provided branch context. These fields are provenance only; they
  /// never make two differently labelled products the same identity.
  final String? branchId;
  final String? location;

  /// Source-provided branch address kept with the exact offer record.
  final String? address;
}
 
/// Canonical source-field names for an explicitly stated regular/crossed-out
/// prospect price. Unknown values remain null so an adapter cannot silently
/// relabel a UVP, discount or unrelated numeric field as a regular price.
String? canonicalProspectRegularPriceSource(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  return switch (normalized) {
    'streichpreis' => 'streichpreis',
    'waspricedisplay' => 'wasPriceDisplay',
    'wasprice' => 'wasPrice',
    'originalprice' => 'originalPrice',
    'regularprice' => 'regularPrice',
    'normalprice' => 'normalPrice',
    'alterpreis' => 'alterPreis',
    'oldprice' => 'oldPrice',
    'pricebefore' => 'priceBefore',
    'previousprice' => 'previousPrice',
    'crossedoutprice' => 'crossedOutPrice',
    'strikethroughprice' => 'strikethroughPrice',
    'waspricenumeric' => 'wasPriceNumeric',
    'original_price' => 'original_price',
    'regular_price' => 'regular_price',
    'normal_price' => 'normal_price',
    'old_price' => 'old_price',
    'previous_price' => 'previous_price',
    'crossed_out_price' => 'crossed_out_price',
    'strikethrough_price' => 'strikethrough_price',
    // A manually reviewed page claim keeps its own provenance marker. It is
    // explicit user evidence, never an inferred adapter field.
    'manualpage' => 'manualPage',
    'manual_page' => 'manual_page',
    'manualreview' => 'manualReview',
    'manual_review' => 'manual_review',
    'secondaryprice' => 'secondaryPrice',
    'spare' => 'spare',
    _ => null,
  };
}

/// Returns whether a non-empty source marker is one of the explicit regular
/// price fields understood by the feed boundary.
bool isKnownProspectRegularPriceSource(String? value) {
  final raw = value?.trim();
  return raw == null ||
      raw.isEmpty ||
      canonicalProspectRegularPriceSource(raw) != null;
}

/// Reusable catalog indexes for batch prospect resolution.
///
/// Prospect coverage and search surfaces may resolve many records against the
/// same catalog snapshot. Keeping normalized EAN/name buckets here avoids
/// rescanning and renormalizing the full catalog for every row while preserving
/// the existing ambiguity rules.
class OfferImportCatalogIndex {
  OfferImportCatalogIndex(Iterable<Product> catalogProducts)
      : products = catalogProducts.toList(growable: false) {
    for (final product in products) {
      final ean = normalizeBarcode(product.ean ?? '');
      if (ean != null) {
        _byEan.putIfAbsent(ean, () => <Product>[]).add(product);
      }
      final name = normalizeIdentityText(product.name);
      if (name.isNotEmpty) {
        _byName.putIfAbsent(name, () => <Product>[]).add(product);
      }
    }
  }

  final List<Product> products;
  final Map<String, List<Product>> _byEan = <String, List<Product>>{};
  final Map<String, List<Product>> _byName = <String, List<Product>>{};

  Iterable<Product> byEan(String ean) => _byEan[ean] ?? const <Product>[];

  Iterable<Product> byName(String name) => _byName[name] ?? const <Product>[];
}

/// Canonicalizes only source tokens already understood by the prospect
/// pipeline. Unknown labels stay null so external adapters cannot silently
/// create a new price source.
String? canonicalProspectSourceToken(String source) =>
    switch (source.trim().toLowerCase()) {
      'leaflet' => 'leaflet',
      'retailer' => 'retailer',
      'retailerwebsite' || 'retailer_website' || 'retailer-website' =>
        'retailerWebsite',
      _ => null,
    };

/// Stable widget identity for an imported prospect record.
///
/// Source IDs are preferred when available. Legacy and image-only feeds may
/// omit them, so the visible fields form a deterministic fallback key instead
/// of producing duplicate empty keys while cards are recycled during scrolling.
String prospectOfferRecordKey(OfferImportRecord record) {
  final sourceId = record.sourceId.trim();
  if (sourceId.isNotEmpty) {
    final branchContext = _prospectOfferBranchContext(record);
    return [
      record.storeName.trim(),
      sourceId,
      if (branchContext.isNotEmpty) branchContext,
    ].join('|');
  }
  final key = [
    record.storeName.trim(),
    record.branchId?.trim() ?? '',
    record.productLabel.trim(),
    record.ean?.trim() ?? '',
    record.offerPrice.toStringAsFixed(2),
    record.originalPrice?.toStringAsFixed(2) ?? '',
    record.regularPriceSource?.trim().toLowerCase() ?? '',
    record.validFrom?.toIso8601String() ?? '',
    record.validUntil.toIso8601String(),
    record.brochureId?.trim() ?? '',
    record.brochurePage?.toString() ?? '',
    record.imageUrl?.trim() ?? '',
  ];
  final branchContext = _prospectOfferBranchContext(record);
  if (branchContext.isNotEmpty) key.add(branchContext);
  return key.join('|');
}

String _prospectOfferBranchContext(OfferImportRecord record) {
  final parts = [
    record.branchId?.trim().toLowerCase() ?? '',
    record.location?.trim().toLowerCase() ?? '',
    record.address?.trim().toLowerCase() ?? '',
  ].where((value) => value.isNotEmpty).toList(growable: false);
  return parts.join('|');
}

/// Stable cache identity for product resolution of an imported prospect.
///
/// Product resolution depends on the exact branch context and on the evidence
/// fields that decide whether a record is eligible. Keeping those inputs in
/// the key prevents a long-lived UI cache from reusing an older EAN, package,
/// price, validity or proof decision for a changed feed row.
String prospectOfferResolutionKey(OfferImportRecord record) => [
      prospectOfferRecordKey(record),
      record.productLabel.trim().toLowerCase(),
      record.ean?.trim().toLowerCase() ?? '',
      record.packageSize?.trim().toLowerCase() ?? '',
      record.offerPrice.toStringAsFixed(4),
      record.originalPrice?.toStringAsFixed(4) ?? '',
      record.regularPriceSource?.trim().toLowerCase() ?? '',
      record.validFrom?.toIso8601String() ?? '',
      record.validUntil.toIso8601String(),
      record.source.trim().toLowerCase(),
      record.sourceAdapter?.trim().toLowerCase() ?? '',
      record.proofRef?.trim() ?? '',
      record.regionalOnly.toString(),
    ].join('|');

String prospectRecordLocationLabel(
  String storeName,
  Iterable<OfferImportRecord> records, {
  String? fallbackLocation,
}) {
  final locations = <String>[];
  for (final record in records) {
    final location = record.location?.trim();
    if (location == null ||
        location.isEmpty ||
        locations.contains(location)) {
      continue;
    }
    locations.add(location);
  }
  if (locations.isNotEmpty) return locations.join(' · ');
  final fallback = fallbackLocation?.trim();
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return configuredProspectBranch(storeName)?.location ?? 'Filiale';
}

/// Returns only records belonging to a prospect that is valid today.
///
/// The feed may retain older prospect records for diagnostics and price
/// history. The user-facing Angebote tab must not expose those records.
List<OfferImportRecord> currentProspectRecords(
  Iterable<OfferImportRecord> records, {
  DateTime? now,
}) => records
    .where(
      (record) => isOfferDateRangeActive(
        validFrom: record.validFrom,
        validUntil: record.validUntil,
        now: now,
      ),
    )
    .toList(growable: false);

/// Returns whether an external offer carries a source reference that can be
/// trusted as evidence. HTTP(S) links need a host; the leaflet scheme is an
/// internal, non-browsable reference used by verified prospect fixtures.
bool hasTrustedOfferProofReference(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return false;
  final uri = Uri.tryParse(raw);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return uri.host.trim().isNotEmpty;
  }
  if (scheme == 'leaflet') {
    final separator = raw.indexOf(':');
    return separator > 0 && raw.substring(separator + 1).trim().isNotEmpty;
  }
  return false;
}

/// Returns whether an offer may be used as current price evidence.
///
/// Manual offers are explicit user input and therefore do not need an
/// external reference. All other sources need a browsable or verified
/// internal proof reference before they can affect shopping-price surfaces or
/// route planning.
bool hasTrustedOfferEvidence(Offer offer) {
  final confidence = offer.evidenceConfidence;
  if (confidence == EvidenceConfidence.probable ||
      confidence == EvidenceConfidence.uncertain) {
    return false;
  }
  if (offer.source.trim().toLowerCase() == 'manual') return true;
  return hasTrustedOfferProofReference(offer.proofRef);
}

/// KaufDA search results are publisher-level evidence unless the adapter
/// supplied an explicit branch assertion. This also protects legacy persisted
/// Offers created before `regionalOnly` was enforced at import time.
bool hasExactOfferBranch(Offer offer) {
  if (offer.sourceAdapter?.trim().toLowerCase() != 'kaufda') return true;
  return offer.locationId?.trim().isNotEmpty == true;
}

/// Repeat the branch assertion at the record boundary so a changed or legacy
/// `regionalOnly: false` flag cannot promote a publisher-level KaufDA result.
bool hasExactOfferRecordBranch(OfferImportRecord record) {
  if (record.sourceAdapter?.trim().toLowerCase() != 'kaufda') return true;
  return record.branchId?.trim().isNotEmpty == true;
}

class OfferImportResolution {
  const OfferImportResolution({
    required this.record,
    this.product,
    this.offer,
    this.reason,
  });

  final OfferImportRecord record;
  final Product? product;
  final Offer? offer;
  final String? reason;

  bool get isResolved => product != null && offer != null;
}

OfferImportResolution resolveOfferImport(
  OfferImportRecord record,
  Iterable<Product> catalogProducts, {
  OfferImportCatalogIndex? catalogIndex,
}) {
  // A publisher-level KaufDA result is useful for discovery, but without an
  // explicit branch assertion it must never become an Offer. Keeping this
  // gate here closes direct callers that do not pass through the prospect
  // tile builder's regional filter.
  if (record.regionalOnly || !hasExactOfferRecordBranch(record)) {
    return OfferImportResolution(record: record, reason: 'regional_only');
  }
  if (!_validPrices(record)) {
    return OfferImportResolution(record: record, reason: 'invalid_price');
  }
  if (record.validFrom != null && record.validUntil.isBefore(record.validFrom!)) {
    return OfferImportResolution(record: record, reason: 'invalid_validity');
  }

  final normalizedLabel = normalizeIdentityText(record.productLabel);
  final index = catalogIndex ?? OfferImportCatalogIndex(catalogProducts);
  final products = index.products;
  final sourceEanText = record.ean?.trim() ?? '';
  final sourceEan = sourceEanText.isEmpty
      ? null
      : normalizeBarcode(sourceEanText);
  if (sourceEanText.isNotEmpty && sourceEan == null) {
    return OfferImportResolution(record: record, reason: 'invalid_ean');
  }

  final Product? product;
  if (sourceEan != null) {
    // A source-provided GTIN is stronger than a display label, but only one
    // catalog product may carry it. Conflicts and missing codes stay reviewable.
    final eanMatches =
        index.byEan(sourceEan).toList(growable: false);
    if (eanMatches.length != 1) {
      return OfferImportResolution(
        record: record,
        reason: eanMatches.isEmpty ? 'ean_mismatch' : 'ambiguous_identity',
      );
    }
    product = eanMatches.single;
  } else {
    // Only the canonical product name may short-circuit identity resolution.
    // Generic aliases such as "Milch" can intentionally belong to multiple
    // variants and must therefore remain ambiguous.
    final exact = index.byName(normalizedLabel).toList(growable: false);

    final strictExact = exactProspectProduct(
      record.productLabel,
      products,
      packageSize: record.packageSize,
    );
    if (strictExact != null) {
      product = strictExact;
    } else if (exact.length == 1) {
      product = exact.single;
    } else if (exact.length > 1) {
      return OfferImportResolution(record: record, reason: 'ambiguous_identity');
    } else {
      final request = identifyProduct(record.productLabel);
      if (!request.isKnown) {
        return OfferImportResolution(record: record, reason: 'unknown_identity');
      }
      final compatible = products.where((candidate) {
        final identities = [candidate.name, ...candidate.aliases]
            .map(identifyProduct)
            .where((identity) => identity.isKnown);
        return identities.any(
          (identity) => compatibleProductIdentity(request, identity),
        );
      }).toList();
      if (compatible.length != 1) {
        return OfferImportResolution(
          record: record,
          reason: compatible.isEmpty ? 'unknown_identity' : 'ambiguous_identity',
        );
      }
      product = compatible.single;
    }
  }

  if (!_matchesRecordPackage(record, product)) {
    return OfferImportResolution(record: record, reason: 'package_mismatch');
  }

  if (record.source.trim().toLowerCase() != 'manual' &&
      !hasTrustedOfferProofReference(record.proofRef)) {
    return OfferImportResolution(record: record, reason: 'missing_proof');
  }

  final package = _offerPackage(record, product);
  final packagePrice = package == null
      ? null
      : normalizedUnitPrice(
          price: record.offerPrice,
          amount: package.amount,
          unit: package.unit,
        );

  final canonicalSource =
      canonicalProspectSourceToken(record.source) ?? record.source;
  final offer = Offer(
    id: 'import|$canonicalSource|${record.sourceId}|${product.id}',
    productId: product.id,
    storeName: record.storeName,
    originalPrice: record.originalPrice ?? record.offerPrice,
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
  return OfferImportResolution(record: record, product: product, offer: offer);
}

bool _validPrices(OfferImportRecord record) {
  final regular = record.originalPrice;
  return record.offerPrice.isFinite &&
      record.offerPrice > 0 &&
      (regular == null ||
          (regular.isFinite && regular > 0 && record.offerPrice <= regular));
}

bool _matchesRecordPackage(OfferImportRecord record, Product product) {
  final packageText = record.packageSize?.trim().isNotEmpty == true
      ? record.packageSize!.trim()
      : record.productLabel;
  if (!_containsPackageEvidence(packageText)) return true;

  final observed = prospectPackage(packageText);
  if (observed == null) return false;
  final expected = product.packageAmount != null && product.packageUnit != null
      ? (amount: product.packageAmount!, unit: product.packageUnit!)
      : prospectPackage(product.unit);
  return expected != null && sameProspectPackage(observed, expected);
}

bool _containsPackageEvidence(String value) => RegExp(
      r'(?:\d+(?:[,.]\d+)?\s*(?:kg|g|mg|ml|cl|l|stk\.?|st\.?|stück|stueck)\b|'
      r'\d+\s*er\s*[- ]?(?:schale|pack(?:ung)?|becher|dose|flasche)\b)',
      caseSensitive: false,
    ).hasMatch(value);

ProspectPackage? _offerPackage(OfferImportRecord record, Product product) {
  final fromRecord = prospectPackage(record.packageSize ?? record.productLabel);
  if (fromRecord != null) return fromRecord;
  if (product.packageAmount != null && product.packageUnit != null) {
    return (amount: product.packageAmount!, unit: product.packageUnit!);
  }
  return prospectPackage(product.unit);
}
/// Keeps widget keys stable for the existing single-row contract while
/// disambiguating providers that reuse one source ID for several articles in
/// the same branch. The caller supplies the current sibling snapshot so a
/// unique source ID keeps its compact legacy key.

/// Computes collision-aware widget keys once for a whole feed snapshot.
///
/// The UI builds only visible sliver children while the feed can contain many
/// records. Precomputing base-key counts keeps key generation linear in the
/// snapshot size instead of scanning every sibling list for every card.
List<String> prospectOfferWidgetKeys(
  Iterable<OfferImportRecord> records,
) {
  final snapshot = records.toList(growable: false);
  final baseKeys = snapshot
      .map(prospectOfferRecordKey)
      .toList(growable: false);
  final counts = <String, int>{};
  for (final base in baseKeys) {
    counts[base] = (counts[base] ?? 0) + 1;
  }
  return List<String>.generate(
    snapshot.length,
    (index) {
      final base = baseKeys[index];
      return counts[base] == 1
          ? base
          : '$base|${prospectOfferResolutionKey(snapshot[index])}';
    },
    growable: false,
  );
}
String prospectOfferWidgetKey(
  OfferImportRecord record,
  Iterable<OfferImportRecord> siblings,
) {
  final base = prospectOfferRecordKey(record);
  final collides = siblings.any(
    (candidate) =>
        !identical(candidate, record) &&
        prospectOfferRecordKey(candidate) == base,
  );
  return collides
      ? '$base|${prospectOfferResolutionKey(record)}'
      : base;
}