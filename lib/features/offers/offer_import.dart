import '../../models/offer.dart';
import '../../models/product.dart';
import '../catalog/product_identity.dart';
import 'offer_filter.dart';
import '../../services/prospect_branch_resolver.dart';

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
    this.category,
    this.branchId,
    this.location,
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

  /// Category supplied by the retailer feed, when the source exposes one.
  /// The UI may fall back to its conservative label classifier when absent;
  /// this field is never inferred into product identity or price evidence.
  final String? category;

  /// Source-provided branch context. These fields are provenance only; they
  /// never make two differently labelled products the same identity.
  final String? branchId;
  final String? location;
}

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
  Iterable<Product> catalogProducts,
) {
  if (!_validPrices(record)) {
    return OfferImportResolution(record: record, reason: 'invalid_price');
  }
  if (record.validFrom != null && record.validUntil.isBefore(record.validFrom!)) {
    return OfferImportResolution(record: record, reason: 'invalid_validity');
  }

  final normalizedLabel = normalizeIdentityText(record.productLabel);
  final products = catalogProducts.toList(growable: false);

  // Only the canonical product name may short-circuit identity resolution.
  // Generic aliases such as "Milch" can intentionally belong to multiple
  // variants and must therefore remain ambiguous.
  final exact = products
      .where((product) =>
          normalizeIdentityText(product.name) == normalizedLabel)
      .toList();

  final Product? product;
  if (exact.length == 1) {
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

  if (record.source != 'manual' &&
      !hasTrustedOfferProofReference(record.proofRef)) {
    return OfferImportResolution(record: record, reason: 'missing_proof');
  }

  final offer = Offer(
    id: 'import|${record.source}|${record.sourceId}|${product.id}',
    productId: product.id,
    storeName: record.storeName,
    originalPrice: record.originalPrice ?? record.offerPrice,
    originalPriceVerified: record.originalPrice != null,
    offerPrice: record.offerPrice,
    validFrom: record.validFrom,
    validUntil: record.validUntil,
    source: record.source,
    proofRef: record.proofRef,
    imageUrl: record.imageUrl,
    locationId: record.branchId,
    region: record.location,
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

