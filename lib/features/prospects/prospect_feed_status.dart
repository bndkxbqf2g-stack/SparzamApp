import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../offers/offer_import.dart';
import '../offers/prospect_price_learning.dart';
import '../offers/offer_filter.dart';
import 'prospect_issue_identity.dart';
import '../../services/prospect_feed_service.dart';

/// Describes whether the regular prices shown for the current prospect feed
/// were merely detected, are being written, or were confirmed locally.
enum ProspectRegularPricePersistenceStatus {
  /// The screen has no shell persistence result and only shows feed evidence.
  standalone,

  /// A new feed is visible while the local persistence write is running.
  pending,

  /// The local persistence write completed successfully, including zero rows.
  succeeded,

  /// The write failed or its result is otherwise unavailable.
  failed,
}
/// Makes the age and provenance of the public prospect feed visible wherever
/// current offers are shown. The timestamp is informational; offer validity
/// is still checked per record before it can be displayed or routed.
class ProspectFeedStatusCard extends StatelessWidget {
  const ProspectFeedStatusCard({
    super.key,
    this.generatedAt,
    this.now,
    this.fromCache = false,
    this.onRefresh,
    this.refreshing = false,
    this.regularPriceCount = 0,
    this.regularPricePersistenceStatus =
        ProspectRegularPricePersistenceStatus.standalone,
  });

  final DateTime? generatedAt;
  final DateTime? now;
  final bool fromCache;
  final Future<void> Function()? onRefresh;
  final bool refreshing;
  /// Current, branch-specific regular prices that can be saved as price basis.
  final int regularPriceCount;
  final ProspectRegularPricePersistenceStatus regularPricePersistenceStatus;

  @override
  Widget build(BuildContext context) {
    if (generatedAt == null && !fromCache && onRefresh == null) {
      return const SizedBox.shrink();
    }
    final timestamp = formatProspectFeedTimestamp(generatedAt);
    final stale = isProspectFeedStale(generatedAt, now: now);
    final theme = Theme.of(context);
    final title = stale
        ? 'Prospektstand veraltet'
        : fromCache
        ? 'Letzter geprüfter Prospektstand'
        : generatedAt == null
        ? 'Prospektstand noch nicht geladen'
        : 'Aktueller Prospektstand';
    final baseSubtitle = fromCache && stale
        ? 'Stand $timestamp. Der Live-Abruf war nicht verfügbar; dieser '
              'lokale Stand ist älter als ${prospectFeedStaleAfter.inHours} '
              'Stunden. Aktualisiere ihn, bevor du neue Angebote übernimmst.'
        : fromCache
        ? 'Stand $timestamp. Der Live-Abruf war nicht verfügbar; '
              'Gültigkeiten werden weiterhin geprüft, abgelaufene Angebote '
              'bleiben ausgeblendet.'
        : generatedAt == null
        ? 'Lade die aktuellen Prospekte, um neue Angebote und Preisbeobachtungen '
              'zu übernehmen.'
        : stale
        ? 'Stand $timestamp. Der Feed ist älter als '
              '${prospectFeedStaleAfter.inHours} Stunden. Aktualisiere ihn, '
              'bevor du neue Angebote übernimmst.'
        : 'Stand $timestamp. Es werden nur aktuell gültige Angebote '
              'angezeigt.';
    final regularPriceStatus = switch (regularPricePersistenceStatus) {
      ProspectRegularPricePersistenceStatus.standalone =>
        regularPriceCount <= 0
            ? null
            : regularPriceCount == 1
            ? '1 regulärer Normalpreis im Feed erkannt; Speicherung nicht bestätigt.'
            : '$regularPriceCount reguläre Normalpreise im Feed erkannt; '
                  'Speicherung nicht bestätigt.',
      ProspectRegularPricePersistenceStatus.pending =>
        'Speicherstatus wird nach dem aktuellen Feed-Lauf geprüft.',
      ProspectRegularPricePersistenceStatus.succeeded =>
        '${regularPriceCount == 1 ? '1 regulärer Normalpreis' : '$regularPriceCount reguläre Normalpreise'} '
            'als Preisbasis gespeichert.',
      ProspectRegularPricePersistenceStatus.failed =>
        'Speicherstatus unbekannt; reguläre Normalpreise wurden in diesem Lauf '
            'nicht bestätigt.',
    };
    final pricePolicy = regularPriceStatus == null
        ? null
        : 'Aktionspreise bleiben an den gültigen Prospektzeitraum gebunden '
            'und werden nicht als Normalpreis gespeichert.';
    final subtitle = [
      baseSubtitle,
      regularPriceStatus,
      pricePolicy,
    ].whereType<String>().join(' ');
    return Card(
      color: fromCache || stale
          ? theme.colorScheme.surfaceContainerHighest
          : null,
      child: ListTile(
        leading: Icon(
          stale
              ? Icons.warning_amber_outlined
              : fromCache
              ? Icons.cloud_off_outlined
              : Icons.verified_outlined,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onRefresh == null
            ? null
            : refreshing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                tooltip: 'Prospekte aktualisieren',
                onPressed: () => onRefresh!(),
                icon: const Icon(Icons.refresh),
              ),
      ),
    );
  }
}

const prospectFeedStaleAfter = Duration(hours: 48);

bool isProspectFeedStale(
  DateTime? generatedAt, {
  DateTime? now,
  Duration maxAge = prospectFeedStaleAfter,
}) {
  if (generatedAt == null) return false;
  final age = (now ?? DateTime.now()).toUtc().difference(generatedAt.toUtc());
  return age > maxAge;
}

String formatProspectFeedTimestamp(DateTime? value) {
  if (value == null) return 'Zeitpunkt unbekannt';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} · $hour:$minute Uhr';
}

/// Describes which evidence the current prospect feed provides for one market.
///
/// This is deliberately a coverage report, not a quality score. Missing source
/// fields remain visible instead of being filled with inferred values.
class ProspectCoverage {
  const ProspectCoverage({
    required this.storeName,
    this.branchId,
    this.location,
    this.address,
    required this.sourceStatus,
    required this.structuredOfferCount,
    required this.regionalOnlyCount,
    required this.pageCount,
    this.availablePageCount,
    this.missingPageCount = 0,
    this.pageStatus = 'unknown',
    this.uncertainProductCount,
    required this.offerImageCount,
    required this.offerCategoryCount,
    required this.offerProofCount,
    this.regularPriceCount = 0,
    this.persistedRegularPriceCount,
    required this.hasBranch,
    required this.hasLocation,
    required this.hasAddress,
    required this.hasValidity,
  });

  final String storeName;
  final String? branchId;
  final String? location;
  final String? address;
  final String sourceStatus;
  final int structuredOfferCount;
  final int regionalOnlyCount;
  final int pageCount;
  /// Publisher-declared page total, when the source exposes one.
  final int? availablePageCount;
  final int missingPageCount;
  final String pageStatus;
  /// Null means the source did not publish an identity-review count.
  final int? uncertainProductCount;
  final int offerImageCount;
  final int offerCategoryCount;
  final int offerProofCount;
  /// Count of explicitly stated, valid regular prices that can be learned
  /// without promoting an offer amount into the regular-price history.
  final int regularPriceCount;
  /// Count confirmed by the local price-observation persistence.
  final int? persistedRegularPriceCount;
  final bool hasBranch;
  final bool hasLocation;
  final bool hasAddress;
  final bool hasValidity;

  bool get hasStructuredOffers => structuredOfferCount > 0;
  int get routeableOfferCount =>
      (structuredOfferCount - regionalOnlyCount)
          .clamp(0, structuredOfferCount)
          .toInt();
  bool get hasPageImages => pageCount > 0;
  bool get hasMissingPages => missingPageCount > 0;

  int get availableStoreSignals => [
    hasBranch,
    hasLocation,
    hasAddress,
    hasValidity,
  ].where((value) => value).length;
}

/// Builds a deterministic, source-faithful coverage report for the visible
/// prospect issues and the already date-filtered offer records.
List<ProspectCoverage> calculateProspectCoverage({
  required Iterable<ProspectIssue> issues,
  required Iterable<OfferImportRecord> records,
  DateTime? now,
  Map<String, int>? persistedRegularPriceCounts,
  Iterable<Product>? catalogProducts,
}) {
  final currentRecords = now == null
      ? records.toList(growable: false)
      : currentProspectRecords(records, now: now);
  final currentIssues = now == null
      ? issues.toList(growable: false)
      : issues
            .where((issue) => _isCurrentProspectIssue(issue, now: now))
            .toList(growable: false);

  final issuesByKey = <String, ProspectIssue>{};
  final branchKeysByStore = <String, Set<String>>{};
  for (final issue in currentIssues) {
    final key = prospectIssueKey(issue);
    issuesByKey.putIfAbsent(key, () => issue);
    if (issue.branchId?.trim().isNotEmpty == true) {
      branchKeysByStore
          .putIfAbsent(issue.storeName, () => <String>{})
          .add(key);
    }
  }

  final recordsByKey = <String, List<OfferImportRecord>>{};
  for (final record in currentRecords) {
    final key = prospectRecordKey(record);
    recordsByKey.putIfAbsent(key, () => []).add(record);
    if (record.branchId?.trim().isNotEmpty == true) {
      branchKeysByStore
          .putIfAbsent(record.storeName, () => <String>{})
          .add(key);
    }
  }

  // A filialloser Legacy-Datensatz remains a safe fallback when exactly
  // one exact branch exists. With multiple branches it stays separate and
  // unknown so one location cannot inherit another location's evidence.
  for (final entry in branchKeysByStore.entries) {
    if (entry.value.length != 1) continue;
    final legacyKey = prospectStoreBranchKey(storeName: entry.key);
    final legacyRecords = recordsByKey.remove(legacyKey);
    if (legacyRecords == null) continue;
    final exactKey = entry.value.single;
    recordsByKey.putIfAbsent(exactKey, () => []).addAll(legacyRecords);
  }

  // Keep configured store placeholders for markets without a branch assertion,
  // but suppress the old store-only placeholder when exact branch cards exist.
  final stores = <String>[
    ...configuredProspectStores.where(
      (store) => !(branchKeysByStore[store]?.isNotEmpty ?? false),
    ),
    ...issuesByKey.keys,
    ...recordsByKey.keys,
  ];
  final uniqueStores = <String>[];
  for (final store in stores) {
    if (!uniqueStores.contains(store)) uniqueStores.add(store);
  }

  return [
    for (final coverageKey in uniqueStores)
      _coverageForStore(
        issuesByKey[coverageKey]?.storeName ??
            _coverageStoreName(coverageKey),
        issuesByKey[coverageKey],
        recordsByKey[coverageKey] ?? const <OfferImportRecord>[],
        persistedRegularPriceCounts == null
            ? null
            : _persistedCoverageCount(
                persistedRegularPriceCounts,
                coverageKey,
                issuesByKey[coverageKey]?.storeName ??
                    _coverageStoreName(coverageKey),
                branchKeysByStore,
              ),
        catalogProducts,
      ),
  ];
}

bool _isCurrentProspectIssue(
  ProspectIssue issue, {
  DateTime? now,
}) {
  final evaluationNow = now;
  final validUntil = issue.validUntil;
  if (evaluationNow == null || validUntil == null) return true;
  return isOfferDateRangeActive(
    validFrom: issue.validFrom,
    validUntil: validUntil,
    now: evaluationNow,
  );
}

ProspectCoverage _coverageForStore(
  String storeName,
  ProspectIssue? issue,
  List<OfferImportRecord> records,
  int? persistedRegularPriceCount,
  Iterable<Product>? catalogProducts,
) {
  final offerImageCount = records
      .where((record) => record.imageUrl?.trim().isNotEmpty == true)
      .length;
  final offerCategoryCount = records
      .where((record) => record.category?.trim().isNotEmpty == true)
      .length;
  final offerProofCount = records
      .where((record) => hasTrustedOfferProofReference(record.proofRef))
      .length;
  final regularPriceCount = records.where(hasLearnableProspectRegularPrice).length;
  final regionalOnlyCount = records.where((record) => record.regionalOnly).length;
  final storedRegularPriceCount = persistedRegularPriceCount?.clamp(0, regularPriceCount).toInt();
  final uncertainProductCount = catalogProducts == null
      ? issue?.uncertainProductCount
      : records.where((record) {
          final reason = resolveOfferImport(record, catalogProducts).reason;
          return reason == 'unknown_identity' ||
              reason == 'ambiguous_identity' ||
              reason == 'package_mismatch' ||
              reason == 'ean_mismatch';
        }).length;
  final recordBranchId = _firstRecordValue(
    records,
    (record) => record.branchId,
  );
  final recordLocation = _firstRecordValue(
    records,
    (record) => record.location,
  );
  final recordAddress = _firstRecordValue(
    records,
    (record) => record.address,
  );
  return ProspectCoverage(
    storeName: storeName,
    branchId: issue?.branchId ?? recordBranchId,
    location: issue?.location ?? recordLocation,
    address: issue?.address ?? recordAddress,
    sourceStatus: issue?.sourceStatus ?? 'unavailable',
    structuredOfferCount: records.length,
    regionalOnlyCount: regionalOnlyCount,
    pageCount: _prospectPageCount(issue),
    availablePageCount: issue?.availablePageCount,
    missingPageCount: issue?.missingPageNumbers.length ?? 0,
    pageStatus: issue?.pageStatus ?? 'unknown',
    uncertainProductCount: uncertainProductCount,
    offerImageCount: offerImageCount,
    offerCategoryCount: offerCategoryCount,
    offerProofCount: offerProofCount,
    regularPriceCount: regularPriceCount,
    persistedRegularPriceCount: storedRegularPriceCount,
    hasBranch: issue?.branchId?.trim().isNotEmpty == true,
    hasLocation: issue?.location?.trim().isNotEmpty == true,
    hasAddress: issue?.address?.trim().isNotEmpty == true,
    hasValidity: issue?.validFrom != null && issue?.validUntil != null,
  );
}

bool hasLearnableProspectRegularPrice(OfferImportRecord record) =>
    isLearnableProspectRegularPrice(record);

String _coverageStoreName(String key) {
  final separator = key.indexOf('#');
  return separator < 0 ? key : key.substring(0, separator);
}

int? _persistedCoverageCount(
  Map<String, int> counts,
  String key,
  String storeName,
  Map<String, Set<String>> branchKeysByStore,
) {
  final exact = counts[key];
  if (exact != null) return exact;
  final branchKeys = branchKeysByStore[storeName] ?? const <String>{};
  // Legacy store-only maps remain safe when this feed has at most one exact
  // branch for that retailer. A successful persistence run has a complete
  // count map, so a missing single-branch entry means zero.
  if (branchKeys.length <= 1) {
    return counts[storeName] ?? 0;
  }
  // A branch-aware map can omit a zero-count branch. Once any exact key is
  // present, an absent exact key is therefore a confirmed zero. A legacy
  // store-only map with multiple branches remains unknown.
  if (branchKeys.any(counts.containsKey)) return 0;
  return null;
}

String? _firstRecordValue(
  Iterable<OfferImportRecord> records,
  String? Function(OfferImportRecord record) read,
) {
  for (final record in records) {
    final value = read(record)?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

int _prospectPageCount(ProspectIssue? issue) {
  if (issue == null) return 0;
  if (issue.pages.isNotEmpty) return issue.pages.length;
  final raw = issue.thumbnailUrl?.trim();
  if (raw == null || raw.isEmpty) return 0;
  final uri = Uri.tryParse(raw);
  final scheme = uri?.scheme.toLowerCase();
  return uri != null &&
          uri.host.trim().isNotEmpty &&
          (scheme == 'http' || scheme == 'https')
      ? 1
      : 0;
}

/// Makes missing prospect evidence explicit without changing offer selection.
class ProspectCoverageCard extends StatefulWidget {
  const ProspectCoverageCard({
    super.key,
    required this.coverage,
    this.regularPricePersistenceStatus =
        ProspectRegularPricePersistenceStatus.standalone,
  });

  final List<ProspectCoverage> coverage;
  final ProspectRegularPricePersistenceStatus regularPricePersistenceStatus;

  @override
  State<ProspectCoverageCard> createState() => _ProspectCoverageCardState();
}

class _ProspectCoverageCardState extends State<ProspectCoverageCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final coverage = widget.coverage;
    if (coverage.isEmpty) return const SizedBox.shrink();
    final marketsWithOffers = coverage
        .where((entry) => entry.hasStructuredOffers)
        .length;
    final marketsWithPages = coverage
        .where((entry) => entry.hasPageImages)
        .length;
    final marketsWithValidity = coverage
        .where((entry) => entry.hasValidity)
        .length;
    final marketsWithProof = coverage
        .where((entry) => entry.offerProofCount > 0)
        .length;
    final marketsWithRegularPrices = coverage
        .where((entry) => entry.regularPriceCount > 0)
        .length;
    final marketsWithStoredRegularPrices = coverage
        .where((entry) => (entry.persistedRegularPriceCount ?? 0) > 0)
        .length;
    final storageSummary = switch (widget.regularPricePersistenceStatus) {
      ProspectRegularPricePersistenceStatus.standalone =>
        'Speicherstatus nicht bestätigt',
      ProspectRegularPricePersistenceStatus.pending => 'Speicherung läuft',
      ProspectRegularPricePersistenceStatus.succeeded =>
        '$marketsWithStoredRegularPrices mit gespeichertem Normalpreis',
      ProspectRegularPricePersistenceStatus.failed => 'Speicherstatus unbekannt',
    };
    final regionalOffers = coverage.fold<int>(
      0,
      (sum, entry) => sum + entry.regionalOnlyCount,
    );
    final totalStructuredOffers = coverage.fold<int>(
      0,
      (sum, entry) => sum + entry.structuredOfferCount,
    );
    final offersWithImages = coverage.fold<int>(
      0,
      (sum, entry) => sum + entry.offerImageCount,
    );
    final offersWithCategories = coverage.fold<int>(
      0,
      (sum, entry) => sum + entry.offerCategoryCount,
    );

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.fact_check_outlined),
        onExpansionChanged: (expanded) {
          if (expanded == _expanded) return;
          setState(() => _expanded = expanded);
        },
        title: const Text('Datenabdeckung der aktuellen Prospekte'),
        subtitle: Text(
          '${coverage.length} Märkte · $marketsWithOffers mit strukturierten '
          'Angeboten · $marketsWithPages mit Bildseiten · '
          '$offersWithImages/$totalStructuredOffers mit Artikelbildern · '
          '$offersWithCategories/$totalStructuredOffers mit Kategorien · '
          '$marketsWithValidity mit Gültigkeitszeitraum · '
          '$marketsWithRegularPrices mit Normalpreis · '
          '$storageSummary · '
          '$marketsWithProof mit Originalnachweis'
          '${regionalOffers == 0 ? '' : ' · $regionalOffers nur regional'}',
        ),
        children: _expanded
            ? [
                for (final entry in coverage)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      _coverageIcon(entry),
                      color: _coverageColor(context, entry),
                    ),
                    title: Text(entry.storeName),
                    subtitle: Text(
                      _coverageDetails(entry, widget.regularPricePersistenceStatus),
                    ),
                    trailing: Text(
                      _sourceStatusLabel(entry.sourceStatus),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ]
            : const <Widget>[],
      ),
    );
  }
}

IconData _coverageIcon(ProspectCoverage coverage) {
  if (coverage.sourceStatus == 'error') return Icons.warning_amber_outlined;
  if (coverage.sourceStatus == 'regional_only') {
    return Icons.location_searching_outlined;
  }
  if (coverage.hasStructuredOffers || coverage.hasPageImages) {
    return Icons.check_circle_outline;
  }
  return Icons.info_outline;
}

Color _coverageColor(BuildContext context, ProspectCoverage coverage) {
  if (coverage.sourceStatus == 'error') return Colors.orange.shade800;
  if (coverage.sourceStatus == 'regional_only') return Colors.deepOrange;
  if (coverage.hasStructuredOffers || coverage.hasPageImages) {
    return Theme.of(context).colorScheme.primary;
  }
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

String _coverageDetails(
  ProspectCoverage coverage,
  ProspectRegularPricePersistenceStatus persistenceStatus,
) {
  final productImages =
      '${coverage.offerImageCount}/${coverage.structuredOfferCount} Produktbilder';
  final categories =
      '${coverage.offerCategoryCount}/${coverage.structuredOfferCount} Kategorien';
  final proofs =
      '${coverage.offerProofCount}/${coverage.structuredOfferCount} Nachweise';
  final regularPrices =
      '${coverage.regularPriceCount}/${coverage.structuredOfferCount} Normalpreise';
  final storedRegularPrices = switch (persistenceStatus) {
    ProspectRegularPricePersistenceStatus.standalone =>
      'Speicherung nicht bestätigt',
    ProspectRegularPricePersistenceStatus.pending => 'Speicherung läuft',
    ProspectRegularPricePersistenceStatus.succeeded =>
      '${coverage.persistedRegularPriceCount ?? 0}/${coverage.structuredOfferCount} gespeichert',
    ProspectRegularPricePersistenceStatus.failed => 'Speicherstatus unbekannt',
  };
  final storeSignals = '${coverage.availableStoreSignals}/4 Filialdaten';
  final pages = coverage.availablePageCount == null
      ? '${coverage.pageCount} Bildseiten'
      : '${coverage.pageCount}/${coverage.availablePageCount} Bildseiten';
  final missingPages = coverage.missingPageCount == 0
      ? ''
      : ' · ${coverage.missingPageCount} fehlende Seiten';
  final uncertain = coverage.uncertainProductCount == null
      ? 'unsichere Zuordnungen nicht ausgewiesen'
      : '${coverage.uncertainProductCount} unsichere Zuordnungen';
  final regional = coverage.regionalOnlyCount == 0
      ? ''
      : ' · ${coverage.regionalOnlyCount} nur regional';
  final branchInfo = [
    if (coverage.branchId?.trim().isNotEmpty == true)
      'Filiale ${coverage.branchId!.trim()}',
    if (coverage.location?.trim().isNotEmpty == true)
      coverage.location!.trim(),
  ].join(' · ');
  final exactStoreInfo = branchInfo.isEmpty ? '' : ' · $branchInfo';
  return '${coverage.structuredOfferCount} strukturierte Angebote'
      '$regional · '
      '$pages$missingPages · $productImages · $categories · '
      '$proofs · '
      '$regularPrices · '
      '$storedRegularPrices · '
      '$uncertain · $storeSignals'
      '$exactStoreInfo';
}

String _sourceStatusLabel(String status) {
  switch (status) {
    case 'ok':
      return 'aktuell';
    case 'current_fallback':
      return 'Fallback';
    case 'metadata_only':
      return 'Metadaten';
    case 'regional_only':
      return 'nur regional';
    case 'error':
      return 'Fehler';
    case 'no_current_offers':
      return 'keine Angebote';
    default:
      return 'unvollständig';
  }
}

