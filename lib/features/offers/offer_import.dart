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
/// Keeps widget keys stable for the existing single-row contract while
/// disambiguating providers that reuse one source ID for several articles in
/// the same branch. The caller supplies the current sibling snapshot so a
/// unique source ID keeps its compact legacy key.
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
      ? '\$base|\$\{prospectOfferResolutionKey(record)\}'
      : base;
}
