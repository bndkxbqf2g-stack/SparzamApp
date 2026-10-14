import 'package:flutter/material.dart';

import '../offers/offer_import.dart';
import '../offers/offer_filter.dart';
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
    final subtitle = regularPriceStatus == null
        ? baseSubtitle
        : '$baseSubtitle $regularPriceStatus';
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
    required this.sourceStatus,
    required this.structuredOfferCount,
    required this.regionalOnlyCount,
    required this.pageCount,
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
  final String sourceStatus;
  final int structuredOfferCount;
  final int regionalOnlyCount;
  final int pageCount;
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
}) {
  final currentRecords = now == null
      ? records.toList(growable: false)
      : currentProspectRecords(records, now: now);
  final currentIssues = now == null
      ? issues.toList(growable: false)
      : issues
            .where((issue) => _isCurrentProspectIssue(issue, now: now))
            .toList(growable: false);

  final issuesByStore = <String, ProspectIssue>{};
  for (final issue in currentIssues) {
    issuesByStore.putIfAbsent(issue.storeName, () => issue);
  }

  final recordsByStore = <String, List<OfferImportRecord>>{};
  for (final record in currentRecords) {
    recordsByStore.putIfAbsent(record.storeName, () => []).add(record);
  }

  final stores = <String>[
    ...configuredProspectStores,
    ...issuesByStore.keys,
    ...recordsByStore.keys,
  ];
  final uniqueStores = <String>[];
  for (final store in stores) {
    if (!uniqueStores.contains(store)) uniqueStores.add(store);
  }

  return [
    for (final storeName in uniqueStores)
      _coverageForStore(
        storeName,
        issuesByStore[storeName],
        recordsByStore[storeName] ?? const <OfferImportRecord>[],
        persistedRegularPriceCounts == null
            ? null
            : (persistedRegularPriceCounts[storeName] ?? 0),
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
  return ProspectCoverage(
    storeName: storeName,
    sourceStatus: issue?.sourceStatus ?? 'unavailable',
    structuredOfferCount: records.length,
    regionalOnlyCount: regionalOnlyCount,
    pageCount: _prospectPageCount(issue),
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

bool hasLearnableProspectRegularPrice(OfferImportRecord record) {
  final regular = record.originalPrice;
  return !record.regionalOnly &&
      hasExactOfferRecordBranch(record) &&
      hasTrustedOfferProofReference(record.proofRef) &&
      regular != null &&
      regular.isFinite &&
      regular > 0 &&
      record.offerPrice.isFinite &&
      record.offerPrice > 0 &&
      // Only a real crossed-out amount is persisted as regular-price history.
      regular > record.offerPrice &&
      (record.validFrom == null ||
          !record.validUntil.isBefore(record.validFrom!));
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
  const ProspectCoverageCard({super.key, required this.coverage});

  final List<ProspectCoverage> coverage;

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
    final hasPersistenceCoverage = coverage.any(
        (entry) => entry.persistedRegularPriceCount != null,
    );
    final marketsWithStoredRegularPrices = coverage
        .where((entry) => (entry.persistedRegularPriceCount ?? 0) > 0)
        .length;
    final storageSummary = hasPersistenceCoverage
        ? '$marketsWithStoredRegularPrices mit gespeichertem Normalpreis'
        : 'Speicherstatus nicht übergeben';
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
                    subtitle: Text(_coverageDetails(entry)),
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

String _coverageDetails(ProspectCoverage coverage) {
  final productImages =
      '${coverage.offerImageCount}/${coverage.structuredOfferCount} Produktbilder';
  final categories =
      '${coverage.offerCategoryCount}/${coverage.structuredOfferCount} Kategorien';
  final proofs =
      '${coverage.offerProofCount}/${coverage.structuredOfferCount} Nachweise';
  final regularPrices =
      '${coverage.regularPriceCount}/${coverage.structuredOfferCount} Normalpreise';
  final storedRegularPrices = coverage.persistedRegularPriceCount == null
      ? 'Speicherstatus unbekannt'
      : '${coverage.persistedRegularPriceCount}/${coverage.structuredOfferCount} gespeichert';
  final storeSignals = '${coverage.availableStoreSignals}/4 Filialdaten';
  final regional = coverage.regionalOnlyCount == 0
      ? ''
      : ' · ${coverage.regionalOnlyCount} nur regional';
  return '${coverage.structuredOfferCount} strukturierte Angebote'
      '$regional · '
      '${coverage.pageCount} Bildseiten · $productImages · $categories · '
      '$proofs · '
      '$regularPrices · '
      '$storedRegularPrices · '
      '$storeSignals';
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

