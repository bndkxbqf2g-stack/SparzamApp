import 'package:flutter/material.dart';

import '../offers/offer_import.dart';
import '../../services/prospect_feed_service.dart';

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
  });

  final DateTime? generatedAt;
  final DateTime? now;
  final bool fromCache;
  final Future<void> Function()? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    if (generatedAt == null && !fromCache && onRefresh == null) {
      return const SizedBox.shrink();
    }
    final timestamp = formatProspectFeedTimestamp(generatedAt);
    final stale = !fromCache &&
        isProspectFeedStale(generatedAt, now: now);
    final theme = Theme.of(context);
    final title = fromCache
        ? 'Letzter geprüfter Prospektstand'
        : generatedAt == null
        ? 'Prospektstand noch nicht geladen'
        : stale
        ? 'Prospektstand veraltet'
        : 'Aktueller Prospektstand';
    final subtitle = fromCache
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
    return Card(
      color: fromCache || stale
          ? theme.colorScheme.surfaceContainerHighest
          : null,
      child: ListTile(
        leading: Icon(
          fromCache
              ? Icons.cloud_off_outlined
              : stale
              ? Icons.warning_amber_outlined
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
}) {
  final issuesByStore = <String, ProspectIssue>{};
  for (final issue in issues) {
    issuesByStore.putIfAbsent(issue.storeName, () => issue);
  }

  final recordsByStore = <String, List<OfferImportRecord>>{};
  for (final record in records) {
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
      ),
  ];
}

ProspectCoverage _coverageForStore(
  String storeName,
  ProspectIssue? issue,
  List<OfferImportRecord> records,
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
  final regionalOnlyCount = records.where((record) => record.regionalOnly).length;
  return ProspectCoverage(
    storeName: storeName,
    sourceStatus: issue?.sourceStatus ?? 'unavailable',
    structuredOfferCount: records.length,
    regionalOnlyCount: regionalOnlyCount,
    pageCount: _prospectPageCount(issue),
    offerImageCount: offerImageCount,
    offerCategoryCount: offerCategoryCount,
    offerProofCount: offerProofCount,
    hasBranch: issue?.branchId?.trim().isNotEmpty == true,
    hasLocation: issue?.location?.trim().isNotEmpty == true,
    hasAddress: issue?.address?.trim().isNotEmpty == true,
    hasValidity: issue?.validFrom != null && issue?.validUntil != null,
  );
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
class ProspectCoverageCard extends StatelessWidget {
  const ProspectCoverageCard({super.key, required this.coverage});

  final List<ProspectCoverage> coverage;

  @override
  Widget build(BuildContext context) {
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
    final regionalOffers = coverage.fold<int>(
      0,
      (sum, entry) => sum + entry.regionalOnlyCount,
    );

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text('Datenabdeckung der aktuellen Prospekte'),
        subtitle: Text(
          '${coverage.length} Märkte · $marketsWithOffers mit strukturierten '
          'Angeboten · $marketsWithPages mit Bildseiten · '
          '$marketsWithValidity mit Gültigkeitszeitraum · '
          '$marketsWithProof mit Originalnachweis'
          '${regionalOffers == 0 ? '' : ' · $regionalOffers nur regional'}',
        ),
        children: [
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
        ],
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
  final storeSignals = '${coverage.availableStoreSignals}/4 Filialdaten';
  final regional = coverage.regionalOnlyCount == 0
      ? ''
      : ' · ${coverage.regionalOnlyCount} nur regional';
  return '${coverage.structuredOfferCount} strukturierte Angebote'
      '$regional · '
      '${coverage.pageCount} Bildseiten · $productImages · $categories · '
      '$proofs · '
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
