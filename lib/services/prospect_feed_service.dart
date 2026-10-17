import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../features/offers/offer_import.dart';
import '../features/offers/offer_filter.dart';
import 'barcode_normalizer.dart';
import 'branch_identity.dart';
import 'prospect_feed_cache.dart';
import 'store_identity.dart';

/// Describes the exact retailer scope that completed a successful feed
/// refresh. A missing [branchId] is an explicit store-level scope; a present
/// branch ID only covers that exact location. This prevents a successful
/// refresh of one same-name branch from promoting another branch's prices.
class ProspectRefreshScope {
  const ProspectRefreshScope({
    required this.storeName,
    this.branchId,
  });

  final String storeName;
  final String? branchId;

  bool matches({
    required String candidateStoreName,
    String? candidateBranchId,
  }) {
    if (!sameStoreLabel(candidateStoreName, storeName)) return false;
    final expectedBranch = canonicalBranchId(branchId);
    if (expectedBranch == null) return true;
    final actualBranch = canonicalBranchId(candidateBranchId);
    return actualBranch != null && actualBranch == expectedBranch;
  }

  String get key =>
      '${storeLabelMatchKey(storeName)}#${canonicalBranchId(branchId) ?? ''}';
}

class ProspectFeedLoadResult {
  const ProspectFeedLoadResult({
    required this.records,
    required this.refreshedStores,
    this.refreshedStoreScopes = const <ProspectRefreshScope>[],
    this.generatedAt,
    this.capturedAt,
    this.prospects = const <ProspectIssue>[],
    this.fromCache = false,
  });

  final List<OfferImportRecord> records;
  /// Legacy store-level refresh labels retained for older callers.
  final List<String> refreshedStores;
  /// Branch-aware refresh scope derived from source metadata.
  final List<ProspectRefreshScope> refreshedStoreScopes;
  final DateTime? generatedAt;
  /// Transport/source capture time used only when the feed has no generatedAt.
  /// It is populated from an explicit feed field or an HTTP response date;
  /// the app never substitutes the local clock.
  final DateTime? capturedAt;
  final List<ProspectIssue> prospects;
  final bool fromCache;

  /// Returns a copy with a source/transport capture time while preserving the
  /// validated feed payload and its original provenance.
  ProspectFeedLoadResult withCapturedAt(DateTime? value) {
    if (capturedAt == value) return this;
    return ProspectFeedLoadResult(
      records: records,
      refreshedStores: refreshedStores,
      refreshedStoreScopes: refreshedStoreScopes,
      generatedAt: generatedAt,
      capturedAt: value,
      prospects: prospects,
      fromCache: fromCache,
    );
  }
}



bool _isCurrentFoodProspectRecord(
  OfferImportRecord record, {
  required DateTime now,
}) =>
    isOfferDateRangeActive(
      validFrom: record.validFrom,
      validUntil: record.validUntil,
      now: now,
    ) &&
    isFoodProspectRecord(
      label: record.productLabel,
      category: record.category,
    );

/// Preserves still-valid food rows and validated page evidence when a
/// source response is temporarily incomplete for an otherwise refreshed scope.
///
/// This is a transport-quality fallback only. It never revives expired rows,
/// never fills a source without an explicit successful scope, and keeps the
/// original row provenance/capture time. Page-only fallback is marked
/// separately so the UI can show an older cover without treating its prices as
/// current data.
ProspectFeedLoadResult preserveCurrentProspectRowsForEmptySources({
  required ProspectFeedLoadResult incoming,
  ProspectFeedLoadResult? fallback,
  DateTime? now,
}) {
  if (fallback == null) return incoming;
  final reference = now ?? DateTime.now();
  final scopes = incoming.refreshedStoreScopes.isNotEmpty
      ? incoming.refreshedStoreScopes
      : incoming.refreshedStores
          .map((storeName) => ProspectRefreshScope(storeName: storeName))
          .toList(growable: false);
  if (scopes.isEmpty) return incoming;

  final incomingCurrent = currentProspectRecords(
    incoming.records,
    now: reference,
  )
      .where((record) => _isCurrentFoodProspectRecord(record, now: reference))
      .toList(growable: false);
  final fallbackCurrent = currentProspectRecords(
    fallback.records,
    now: reference,
  )
      .where((record) => _isCurrentFoodProspectRecord(record, now: reference))
      .toList(growable: false);

  final additions = <OfferImportRecord>[];
  // Historical or malformed incoming rows must not block a still-valid
  // fallback row with the same source ID. A current incoming row already
  // short-circuits its scope above, so only current keys belong here.
  final knownKeys = incomingCurrent.map(prospectOfferRecordKey).toSet();
  final fallbackCounts = <String, int>{};
  for (final scope in scopes) {
    final hasIncomingRows = incomingCurrent.any(
      (record) => scope.matches(
        candidateStoreName: record.storeName,
        candidateBranchId: record.branchId,
      ),
    );
    if (hasIncomingRows) continue;

    final candidates = fallbackCurrent
        .where(
          (record) => scope.matches(
            candidateStoreName: record.storeName,
            candidateBranchId: record.branchId,
          ),
        )
        .toList(growable: false);
    if (candidates.isEmpty) continue;

    var addedForScope = 0;
    for (final record in candidates) {
      if (!knownKeys.add(prospectOfferRecordKey(record))) continue;
      additions.add(record);
      addedForScope++;
    }
    if (addedForScope > 0) {
      fallbackCounts[scope.key] = addedForScope;
    }
  }
  // A newer source response can keep valid row metadata while omitting page
  // images during a partial publisher refresh. Reuse only a matching local
  // prospect for the exact store/branch scope; never cross-promote a branch.
  final fallbackProspectsByScope = <String, ProspectIssue>{};
  for (final scope in scopes) {
    for (final issue in fallback.prospects) {
      if (!scope.matches(
        candidateStoreName: issue.storeName,
        candidateBranchId: issue.branchId,
      )) {
        continue;
      }
      final current = fallbackProspectsByScope[scope.key];
      if (current == null ||
          issue.pages.length > current.pages.length ||
          (current.thumbnailUrl == null && issue.thumbnailUrl != null)) {
        fallbackProspectsByScope[scope.key] = issue;
      }
    }
  }

  final fallbackPageScopes = <String>{};
  for (final scope in scopes) {
    final fallbackIssue = fallbackProspectsByScope[scope.key];
    if (fallbackIssue == null ||
        (fallbackIssue.pages.isEmpty && fallbackIssue.thumbnailUrl == null)) {
      continue;
    }
    final hasIncomingPageEvidence = incoming.prospects.any(
      (issue) =>
          scope.matches(
            candidateStoreName: issue.storeName,
            candidateBranchId: issue.branchId,
          ) &&
          (issue.pages.isNotEmpty || issue.thumbnailUrl != null),
    );
    if (!hasIncomingPageEvidence) {
      fallbackPageScopes.add(scope.key);
    }
  }
  if (additions.isEmpty && fallbackPageScopes.isEmpty) return incoming;

  final affectedProspects = <ProspectIssue>[
    ...incoming.prospects.map(
      (issue) {
        ProspectRefreshScope? matchedScope;
        for (final scope in scopes) {
          if ((!fallbackCounts.containsKey(scope.key) &&
                  !fallbackPageScopes.contains(scope.key)) ||
              !scope.matches(
                candidateStoreName: issue.storeName,
                candidateBranchId: issue.branchId,
              )) {
            continue;
          }
          matchedScope = scope;
          break;
        }
        if (matchedScope == null) return issue;

        final fallbackCount = fallbackCounts[matchedScope.key] ?? 0;
        final fallbackIssue = fallbackProspectsByScope[matchedScope.key];
        final useFallbackPages = fallbackPageScopes.contains(matchedScope.key) &&
            issue.pages.isEmpty &&
            fallbackIssue != null &&
            fallbackIssue.pages.isNotEmpty;
        if (fallbackCount == 0 && !useFallbackPages) return issue;

        final pages = useFallbackPages
            ? (fallbackIssue?.pages ?? issue.pages)
            : issue.pages;
        final fallbackThumbnail = fallbackIssue?.thumbnailUrl ??
            (fallbackIssue == null || fallbackIssue.pages.isEmpty
                ? null
                : fallbackIssue.pages.first.imageUrl);
        final pageStatus = useFallbackPages &&
                issue.pageStatus.trim().toLowerCase() == 'unknown'
            ? (fallbackIssue?.pageStatus ?? issue.pageStatus)
            : issue.pageStatus;
        final loadedPageCount = useFallbackPages &&
                (issue.loadedPageCount == null || issue.loadedPageCount == 0)
            ? (fallbackIssue?.loadedPageCount ?? pages.length)
            : issue.loadedPageCount;
        final missingPageNumbers = useFallbackPages &&
                issue.missingPageNumbers.isEmpty
            ? (fallbackIssue?.missingPageNumbers ??
                issue.missingPageNumbers)
            : issue.missingPageNumbers;
        final pageCountKnown = issue.pageCountKnown ||
            (useFallbackPages && fallbackIssue?.pageCountKnown == true);
        final title = issue.title.trim().toLowerCase() == 'prospekt'
            ? (fallbackIssue?.title ?? issue.title)
            : issue.title;
        final fallbackStatus =
            fallbackCount > 0 ? 'current_fallback' : 'stale_fallback';

        return ProspectIssue(
          storeName: issue.storeName,
          title: title,
          pages: pages,
          url: issue.url ?? fallbackIssue?.url,
          thumbnailUrl: issue.thumbnailUrl ?? fallbackThumbnail,
          branchId: issue.branchId,
          location: issue.location ?? fallbackIssue?.location,
          address: issue.address ?? fallbackIssue?.address,
          sourceAdapter: issue.sourceAdapter ?? fallbackIssue?.sourceAdapter,
          sourceStatus: fallbackStatus,
          recordCount: issue.recordCount > fallbackCount
              ? issue.recordCount
              : fallbackCount,
          availablePageCount:
              issue.availablePageCount ?? fallbackIssue?.availablePageCount,
          loadedPageCount: loadedPageCount,
          missingPageNumbers: missingPageNumbers,
          pageStatus: pageStatus,
          pageCountKnown: pageCountKnown,
          uncertainProductCount:
              issue.uncertainProductCount ?? fallbackIssue?.uncertainProductCount,
          validFrom: issue.validFrom ?? fallbackIssue?.validFrom,
          validUntil: issue.validUntil ?? fallbackIssue?.validUntil,
        );
      },
    ),
  ];

  // Keep the visible prospect surface usable even if a malformed feed omitted
  // the metadata-only issue row for a scope that received row or page fallback.
  for (final scope in scopes) {
    final fallbackCount = fallbackCounts[scope.key] ?? 0;
    final usePageFallback = fallbackPageScopes.contains(scope.key);
    if ((fallbackCount == 0 && !usePageFallback) ||
        affectedProspects.any(
          (issue) => scope.matches(
            candidateStoreName: issue.storeName,
            candidateBranchId: issue.branchId,
          ),
        )) {
      continue;
    }
    final fallbackIssue = fallbackProspectsByScope[scope.key];
    if (fallbackIssue == null) continue;
    affectedProspects.add(
      ProspectIssue(
        storeName: fallbackIssue.storeName,
        title: fallbackIssue.title,
        pages: fallbackIssue.pages,
        url: fallbackIssue.url,
        thumbnailUrl: fallbackIssue.thumbnailUrl ??
            (fallbackIssue.pages.isEmpty
                ? null
                : fallbackIssue.pages.first.imageUrl),
        branchId: fallbackIssue.branchId,
        location: fallbackIssue.location,
        address: fallbackIssue.address,
        sourceAdapter: fallbackIssue.sourceAdapter,
        sourceStatus:
            fallbackCount > 0 ? 'current_fallback' : 'stale_fallback',
        recordCount: fallbackCount,
        availablePageCount: fallbackIssue.availablePageCount,
        loadedPageCount: fallbackIssue.loadedPageCount ??
            fallbackIssue.pages.length,
        missingPageNumbers: fallbackIssue.missingPageNumbers,
        pageStatus: fallbackIssue.pageStatus,
        pageCountKnown: fallbackIssue.pageCountKnown,
        uncertainProductCount: fallbackIssue.uncertainProductCount,
        validFrom: fallbackIssue.validFrom,
        validUntil: fallbackIssue.validUntil,
      ),
    );
  }

  return ProspectFeedLoadResult(
    records: <OfferImportRecord>[
      ...incoming.records,
      ...additions,
    ],
    refreshedStores: incoming.refreshedStores,
    refreshedStoreScopes: incoming.refreshedStoreScopes,
    generatedAt: incoming.generatedAt,
    capturedAt: incoming.capturedAt,
    prospects: affectedProspects,
    fromCache: incoming.fromCache,
  );
}

typedef ProspectFeedAssetLoader = Future<String> Function();

class ProspectIssue {
  const ProspectIssue({
    required this.storeName,
    required this.title,
    required this.pages,
    this.url,
    this.thumbnailUrl,
    this.branchId,
    this.location,
    this.address,
    this.sourceAdapter,
    this.sourceStatus = 'unknown',
    this.recordCount = 0,
    this.availablePageCount,
    this.loadedPageCount,
    this.missingPageNumbers = const <int>[],
    this.pageStatus = 'unknown',
    this.pageCountKnown = false,
    this.uncertainProductCount,
    this.validFrom,
    this.validUntil,
  });
  final String storeName;
  final String title;
  final List<ProspectPage> pages;
  final String? url;
  final String? thumbnailUrl;
  final String? branchId;
  final String? location;
  final String? address;
  /// Technical adapter that supplied the prospect metadata, when known.
  /// It is provenance only and never creates an offer or product identity.
  final String? sourceAdapter;
  final String sourceStatus;
  final int recordCount;
  /// Number of pages the publisher declared for this prospect, when known.
  final int? availablePageCount;
  /// Number of page images that were actually included in the feed.
  final int? loadedPageCount;
  final List<int> missingPageNumbers;
  final String pageStatus;
  final bool pageCountKnown;
  /// A source-reported count of records that still need identity review.
  /// Null means that the source did not publish this diagnostic.
  final int? uncertainProductCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
}

class ProspectPage {
  const ProspectPage({
    required this.number,
    required this.imageUrl,
    this.zoomUrl,
    this.keyWords = '',
  });
  final int number;
  final String imageUrl;
  final String? zoomUrl;
  final String keyWords;
}

class _ProspectPageImageCandidate {
  const _ProspectPageImageCandidate({
    required this.imageUrl,
    required this.branchId,
    required this.validFrom,
    required this.validUntil,
  });

  final String imageUrl;
  final String? branchId;
  final DateTime? validFrom;
  final DateTime? validUntil;
}

class _ProspectSourceMetadata {
  const _ProspectSourceMetadata({
    required this.storeName,
    required this.url,
    required this.branchId,
    required this.location,
    required this.address,
    required this.status,
    required this.recordCount,
    required this.sourceAdapter,
  });

  final String storeName;
  final String? url;
  final String? branchId;
  final String? location;
  final String? address;
  final String status;
  final int recordCount;
  final String? sourceAdapter;
}


// Retailer feeds can contain household and seasonal campaign articles next to
// food. Keep the app-side boundary defensive even when an older public feed
// was generated before the refresh workflow applied its food-only filter.
final _nonFoodProspectLabel = RegExp(
  r'\b(?:'
  r'hausschuhe|schuhe|bettwäsche|bettwaesche|bekleidung|sweatbekleidung|'
  r'fleece|pyjama|anti-rutsch|platzset|tischläufer|tischlaeufer|kissen|'
  r'spielzeug|bausteine|figuren|laterne|kostüm|kostuem|stabkerzen|'
  r'lichterkette|naturgeräuschebox|naturgeraeuschebox|waffeleisen|'
  r'möbel|moebel|garten|pflanzen(?!öl)|pflanze(?!nöl)|orchidee|herbstheide|chrysanthemen|'
  r'skimmie|elektronik|handy|fernseher|hörgerätebatterien|'
  r'hoergeraetebatterien|batterien|waschmittel|geschirrreiniger|wc-ente|'
  r'shampoo|spülung|spuelung|kosmetik|tierbedarf|katzennahrung|kratzhaus|'
  r'katzenstreu|drucker|glade|vileda|somat|ariel|lenor|perwoll|garnier|'
  r'nivea|colgate|zahnbürste|zahnbuerste|zahnpasta|deospray|handcreme|'
  r'bodylotion|rexona|neutrogena|odol|dr\.\s*best|pril|finish|swiffer|'
  r'dirt\s+devil|cleanmaxx|parkside|multifunktionswerkzeug|dampfreiniger|'
  r'wäschetrockner|waeschetrockner|ofenhandschuh|strukturpflanze|'
  r'herbstpflanzen|küchenrolle|kuechenrolle|toilettenpapier|servietten|'
  r'haushaltstücher|haushaltstuecher|wärmepad|waermepad|wärmepflaster|'
  r'waermepflaster|tabletten|halstabletten|kollagenpulver|'
  r'gutschein-adventskalender|mila.?s\s+world|max.?s\s+world|home\s+creation|'
  r'block\s+tech|ambiano|cachet|novitesse|multinorm|rose|taschentücher|'
  r'taschentuecher|poly\s+palette|schwarzkopf|taft|dove|duschgel|dusche|'
  r'haarreif|wasserkocher|kochgeschirr|haushaltshelfer|besenheide|'
  r'geschenkpapier|geschenkband|geschenktaschen|paw\s+patrol|franzis|playmobil|craze|lego|'
  r'funko|mattel|revell|majorette|kosmos|spice\s*&\s*soul|silvercrest|'
  r'livarno|liv&bo|handbrause|frottier|trinkglas|tasche.{0,15}halloween'
  r'|bepflanzt(?:es|e)?|holzgefäß|holzgefaess|badesalz|anginetten|'
  r'purina|gourmet\s+(?:perle|gold)|vitakraft|sheba|calgon|cosmea|'
  r'viss|wc-frisch|pampers|gillette|emyo|slipeinlagen|hundesnack|hundefutter|'
  r'katzenfutter|tiernahrung|'
  r'tasse|kaffeemaschine|filterkaffeemaschine|kaffeepadmaschine|multizerkleinerer|kontaktgrill|'
  r'kochplatte|allesschneider|gemüseschneider|gemueseschneider|fleischwolf|'
  r'weichspüler|weichspueler|dampfbügelstation|dampfbuegelstation|'
  r'sekundenkleber|alleskleber|wandweiß(?:\s|$)|wandweiss(?:\s|$)|filterkartuschen|'
  r'trinkflasche|brotkorb|brotbox|frühstücksbrett|fruehstuecksbrett|'
  r'deko|fenstersticker|spinnennetz|weihnachtsbeleuchtung|lichtergirlande|'
  r'mangoholz|grabstrauß|grabstrauss|grabkranz|grabschale|urnen|gesteck|'
  r'hoodie|sweathose|retroshorts|loungewear|t-shirts|ballerinas|'
  r'klumpstreu|wc-garnitur|zierpaprika|bubikopf'
  r')\b',
  caseSensitive: false,
);

final _nonFoodProspectCategory = RegExp(
  r'(?:tierbedarf|tiernahrung|haustierbedarf|pet\s*food)',
  caseSensitive: false,
);
final _foodInNonFoodProspectCategory = RegExp(
  r'(?:slim\s+shake|protein-riegel)',
  caseSensitive: false,
);

bool isFoodProspectLabel(String label) =>
    label.trim().isNotEmpty && !_nonFoodProspectLabel.hasMatch(label);

bool isFoodProspectRecord({
  required String label,
  String? category,
  String? subcategory,
  String? department,
}) {
  final metadata = [category, subcategory, department]
      .whereType<String>()
      .join(' ');
  return isFoodProspectLabel(label) &&
      (!_nonFoodProspectCategory.hasMatch(metadata) ||
          _foodInNonFoodProspectCategory.hasMatch(label));
}

/// Projects a validated feed to the current food-only surface used by the
/// visible offers/prospect tabs and automatic prospect-price learning.
///
/// The parser already applies this boundary for fresh responses. Keeping the
/// projection here makes legacy cache and injected test feeds obey the same
/// rule without changing their stored diagnostic rows.
List<OfferImportRecord> currentFoodProspectRecords(
  Iterable<OfferImportRecord> records, {
  DateTime? now,
}) =>
    currentProspectRecords(records, now: now)
        .where(
          (record) => isFoodProspectRecord(
            label: record.productLabel,
            category: record.category,
          ),
        )
        .toList(growable: false);

const configuredProspectStores = <String>[
  'Lidl',
  'ALDI Süd',
  'EDEKA',
  'Kaufland',
  'PENNY',
  'Netto',
];

String? officialProspectUrl(String storeName, [String? fallback]) {
  switch (storeName) {
    case 'ALDI Süd':
      return 'https://www.aldi-sued.de/';
    case 'EDEKA':
      return 'https://www.edeka.de/markt-id/8002976/prospekt.jsp';
    case 'Kaufland':
      return 'https://filiale.kaufland.de/prospekte.html';
    case 'PENNY':
      return 'https://www.penny.de/angebote';
    case 'Netto':
      return 'https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371';
    default:
      return fallback;
  }
}

List<dynamic> _listValue(Object? value) =>
    value is List<dynamic> ? value : const <dynamic>[];

String? _optionalNonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _ProspectBranchContext {
  const _ProspectBranchContext({
    this.branchId,
    this.location,
    this.address,
  });

  final String? branchId;
  final String? location;
  final String? address;
}

const _directProspectBranchKeys = <String>[
  'branchId',
  'branchID',
  'branch_id',
  'branchCode',
  'branch_code',
  'locationId',
  'location_id',
];

const _nestedProspectBranchKeys = <String>[
  ..._directProspectBranchKeys,
  'storeId',
  'store_id',
  'id',
  'code',
];

const _nestedProspectLocationKeys = <String>[
  'location',
  'city',
  'town',
  'ort',
];

const _nestedProspectAddressKeys = <String>[
  'address',
  'streetAddress',
  'formattedAddress',
  'fullAddress',
];

String? _prospectBranchScalar(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num && value.isFinite) return value.toString();
  return null;
}

String? _prospectBranchValue(
  Map<String, dynamic> value,
  Iterable<String> keys,
) {
  for (final key in keys) {
    final candidate = _prospectBranchScalar(value[key]);
    if (candidate != null) return candidate;
  }
  return null;
}

String? _prospectNestedBranchValue(
  Map<String, dynamic> value,
  Iterable<String> keys, {
  required bool allowGenericId,
}) {
  String? readFrom(Iterable<String> containerKeys, bool includeGenericId) {
    for (final containerKey in containerKeys) {
      final nested = value[containerKey];
      if (nested is! Map) continue;
      final candidateKeys = includeGenericId
          ? keys
          : keys.where((key) => !const ['id', 'code'].contains(key));
      for (final key in candidateKeys) {
        final candidate = _prospectBranchScalar(nested[key]);
        if (candidate != null) return candidate;
      }
    }
    return null;
  }

  return readFrom(
        const ['branch', 'branchInfo', 'storeBranch'],
        allowGenericId,
      ) ??
      readFrom(
        const ['storeLocation', 'locationInfo', 'store', 'location'],
        false,
      );
}

_ProspectBranchContext _prospectBranchContext(Map<String, dynamic> value) {
  final branchId = _prospectBranchValue(value, _directProspectBranchKeys) ??
      _prospectNestedBranchValue(
        value,
        _nestedProspectBranchKeys,
        allowGenericId: true,
      );
  final location = _prospectBranchValue(
        value,
        const ['location', 'city', 'town', 'ort'],
      ) ??
      _prospectNestedBranchValue(
        value,
        _nestedProspectLocationKeys,
        allowGenericId: false,
      );
  final address = _prospectBranchValue(
        value,
        const ['address', 'streetAddress', 'formattedAddress', 'fullAddress'],
      ) ??
      _prospectNestedBranchValue(
        value,
        _nestedProspectAddressKeys,
        allowGenericId: false,
      );
  return _ProspectBranchContext(
    branchId: branchId,
    location: location,
    address: address,
  );
}

const _prospectStartDateKeys = <String>[
  'validFrom',
  'valid_from',
  'offerStartDate',
  'offer_start_date',
  'startDate',
  'start_date',
  'from',
  'start',
];

const _prospectEndDateKeys = <String>[
  'validUntil',
  'valid_until',
  'offerEndDate',
  'offer_end_date',
  'endDate',
  'end_date',
  'expiresAt',
  'expires_at',
  'to',
  'end',
];

const _prospectValidityContainers = <String>[
  'validity',
  'validityPeriod',
  'validity_period',
  'dateRange',
  'date_range',
  'period',
  'offerPeriod',
  'offer_period',
];

Object? _prospectValidityValue(
  Map<String, dynamic> value, {
  required bool start,
}) {
  final keys = start ? _prospectStartDateKeys : _prospectEndDateKeys;
  for (final key in keys) {
    final candidate = value[key];
    if (candidate != null) return candidate;
  }
  for (final containerKey in _prospectValidityContainers) {
    final nested = value[containerKey];
    if (nested is! Map) continue;
    for (final key in keys) {
      final candidate = nested[key];
      if (candidate != null) return candidate;
    }
  }
  return null;
}

String? _prospectDateText(Object? value, {int depth = 0}) {
  if (depth > 2) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is DateTime) return value.toIso8601String();
  if (value is Map) {
    for (final key in const [
      'date',
      'value',
      'iso',
      'isoDate',
      'timestamp',
      'from',
      'to',
      'start',
      'end',
    ]) {
      final nested = _prospectDateText(value[key], depth: depth + 1);
      if (nested != null) return nested;
    }
  }
  return null;
}

// Feed sections can spell the same retailer with umlauts or ae/oe/ue.
// This key is metadata-only; displayed labels and branch IDs stay unchanged.
String _prospectStoreMetadataKey(String value) {
  final normalized = normalizeStoreIdentityText(value);
  return normalized
      .replaceAll('ae', 'a')
      .replaceAll('oe', 'o')
      .replaceAll('ue', 'u');
}



DateTime? _httpResponseCapturedAt(Map<String, String> headers) {
  for (final headerName in const ['last-modified', 'date']) {
    String? raw;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == headerName) {
        raw = entry.value;
        break;
      }
    }
    final parsed = _parseHttpHeaderDate(raw);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _parseHttpHeaderDate(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final iso = DateTime.tryParse(trimmed);
  if (iso != null &&
      (trimmed.endsWith('Z') ||
          RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed))) {
    return iso.toUtc();
  }

  final match = RegExp(
    r'^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),\s*'
    r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
    r'(\d{2}):(\d{2}):(\d{2})\s+(?:GMT|UTC)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (match == null) return null;

  const months = <String, int>{
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };
  final month = months[match.group(2)!.toLowerCase()];
  if (month == null) return null;
  try {
    return DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  } on FormatException {
    return null;
  }
}

class ProspectFeedService {
  ProspectFeedService({
    http.Client? client,
    ProspectFeedCache? cache,
    ProspectFeedAssetLoader? bundledLoader,
    this.networkEnabled = true,
  })
    : _client = client ?? http.Client(),
      _cache = cache ?? SharedPreferencesProspectFeedCache(),
      _bundledLoader = bundledLoader ??
          (() => rootBundle.loadString(ProspectFeedService.bundledFeedAsset));

  static const bundledFeedAsset = 'assets/prospects/current.json';
  static const feedUrl =
      'https://raw.githubusercontent.com/bndkxbqf2g-stack/SparzamApp/'
      'main/assets/prospects/current.json';

  final http.Client _client;
  final ProspectFeedCache _cache;
  final ProspectFeedAssetLoader _bundledLoader;
  final bool networkEnabled;
  Future<ProspectFeedLoadResult>? _inFlight;

  // The shell can read cache and bundled data more than once during startup
  // and resume. Keep one parsed snapshot for each provenance so the same JSON
  // is not decoded repeatedly on the UI isolate.
  String? _memoizedLiveRaw;
  ProspectFeedLoadResult? _memoizedLiveResult;
  String? _memoizedLocalRaw;
  ProspectFeedLoadResult? _memoizedLocalResult;

  ProspectFeedLoadResult _parse(
    String raw, {
    required bool fromCache,
  }) {
    final cachedRaw = fromCache ? _memoizedLocalRaw : _memoizedLiveRaw;
    final cachedResult = fromCache
        ? _memoizedLocalResult
        : _memoizedLiveResult;
    if (cachedResult != null && cachedRaw == raw) {
      return cachedResult;
    }

    final parsed = parseProspectFeed(raw, fromCache: fromCache);
    if (fromCache) {
      _memoizedLocalRaw = raw;
      _memoizedLocalResult = parsed;
    } else {
      _memoizedLiveRaw = raw;
      _memoizedLiveResult = parsed;
    }
    return parsed;
  }

  /// Closes the client created by this service. Callers that inject a client
  /// retain ownership of that client and may close it themselves.
  void close() => _client.close();

  Future<ProspectFeedLoadResult> load() {
    final running = _inFlight;
    if (running != null) return running;

    final started = _loadNow();
    _inFlight = started;
    started.then<void>(
      (_) {
        if (identical(_inFlight, started)) _inFlight = null;
      },
      onError: (Object _, StackTrace _) {
        if (identical(_inFlight, started)) _inFlight = null;
      },
    );
    return started;
  }

  /// Returns the newest locally available validated feed without any
  /// network request. The shell uses this for an immediate first render and
  /// follows it with the normal online refresh.
  Future<ProspectFeedLoadResult?> loadCached() =>
      _loadNewestLocalFeed();

  Future<ProspectFeedLoadResult> _loadNow() async {
    if (!networkEnabled) {
      final local = await _loadNewestLocalFeed();
      if (local != null) return local;
      throw StateError(
        'Prospektfeed ist deaktiviert und offline nicht verfügbar.',
      );
    }
    try {
      final response = await _client
          .get(
            Uri.parse(feedUrl),
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'SparzamApp/1.0 (prospect feed)',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Prospektfeed HTTP ${response.statusCode}');
      }
      final parsed = _parse(response.body, fromCache: false);
      // Prefer an explicit feed timestamp. The response header is a
      // transport/source capture fallback only; local clock time is never used.
      final result = parsed.capturedAt == null
          ? parsed.withCapturedAt(_httpResponseCapturedAt(response.headers))
          : parsed;
      // A CDN or a temporarily stale publisher response must not replace a
      // newer validated local snapshot. Equal timestamps still prefer the
      // successful live response.
      final local = await _loadNewestLocalFeed();
      final selected = _newestFeed(result, local)!;
      final guarded = identical(selected, result)
          ? preserveCurrentProspectRowsForEmptySources(
              incoming: result,
              fallback: local,
              now: DateTime.now(),
            )
          : selected;
      if (identical(guarded, result)) {
        // A cache failure must never hide a valid live feed. A response that
        // needed current-row fallback is deliberately not cached over the
        // older validated snapshot.
        try {
          await _cache.save(response.body);
          final metadataCache = _cache is ProspectFeedCaptureMetadataCache
              ? _cache as ProspectFeedCaptureMetadataCache
              : null;
          final capturedAt = result.capturedAt;
          if (metadataCache != null && capturedAt != null) {
            await metadataCache.saveCapturedAt(response.body, capturedAt);
          }
        } catch (_) {
          // The next online refresh can try to repair the cache.
        }
      }
      return guarded;
    } catch (error, stackTrace) {
      final local = await _loadNewestLocalFeed();
      if (local != null) return local;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Returns the newest validated snapshot available without the network.
  ///
  /// The cache can be older than the bundled asset after an app update. Read
  /// both sources and compare their feed timestamps so an old device cache
  /// cannot hide the newer asset. If the newest local snapshot has an empty
  /// current source, still-valid rows from another local snapshot are merged
  /// through the explicit fallback boundary above.
  Future<ProspectFeedLoadResult?> _loadNewestLocalFeed() async {
    final candidates = await _loadLocalFeeds();
    final newest = _newestOf(candidates);
    if (newest == null) return null;
    final fallback = _localFallbackForEmptyScopes(
      candidates,
      incoming: newest,
      now: DateTime.now(),
    );
    return preserveCurrentProspectRowsForEmptySources(
      incoming: newest,
      fallback: fallback,
      now: DateTime.now(),
    );
  }

  Future<List<ProspectFeedLoadResult>> _loadLocalFeeds() async {
    final local = await Future.wait<ProspectFeedLoadResult?>([
      _loadCachedFeed(),
      _loadBundledFeed(),
    ]);
    return local.whereType<ProspectFeedLoadResult>().toList(growable: false);
  }

  ProspectFeedLoadResult? _newestOf(
    Iterable<ProspectFeedLoadResult> feeds,
  ) {
    ProspectFeedLoadResult? newest;
    for (final feed in feeds) {
      newest = _newestFeed(newest, feed);
    }
    return newest;
  }

  ProspectFeedLoadResult? _localFallbackForEmptyScopes(
    Iterable<ProspectFeedLoadResult> candidates, {
    required ProspectFeedLoadResult incoming,
    required DateTime now,
  }) {
    final scopes = incoming.refreshedStoreScopes.isNotEmpty
        ? incoming.refreshedStoreScopes
        : incoming.refreshedStores
            .map((storeName) => ProspectRefreshScope(storeName: storeName));
    ProspectFeedLoadResult? fallback;
    for (final candidate in candidates) {
      if (identical(candidate, incoming)) continue;
      final hasCurrentRows = candidate.records.any(
        (record) => _isCurrentFoodProspectRecord(record, now: now) &&
            scopes.any(
              (scope) => scope.matches(
                candidateStoreName: record.storeName,
                candidateBranchId: record.branchId,
              ),
            ),
      );
      final hasPageEvidence = candidate.prospects.any(
        (issue) =>
            scopes.any(
              (scope) => scope.matches(
                candidateStoreName: issue.storeName,
                candidateBranchId: issue.branchId,
              ),
            ) &&
            (issue.pages.isNotEmpty || issue.thumbnailUrl != null),
      );
      if (!hasCurrentRows && !hasPageEvidence) continue;
      fallback = _newestFeed(fallback, candidate);
    }
    return fallback;
  }

  ProspectFeedLoadResult? _newestFeed(
    ProspectFeedLoadResult? first,
    ProspectFeedLoadResult? second,
  ) {
    if (first == null) return second;
    if (second == null) return first;

    final firstAt = first.generatedAt ?? first.capturedAt;
    final secondAt = second.generatedAt ?? second.capturedAt;
    if (firstAt == null) return secondAt == null ? first : second;
    if (secondAt == null) return first;
    return firstAt.isBefore(secondAt) ? second : first;
  }

  Future<ProspectFeedLoadResult?> _loadCachedFeed() async {
    String? raw;
    try {
      raw = await _cache.load();
    } catch (_) {
      return null;
    }
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final parsed = _parse(raw, fromCache: true);
      if (parsed.generatedAt != null || parsed.capturedAt != null) {
        return parsed;
      }
      final metadataCache = _cache is ProspectFeedCaptureMetadataCache
          ? _cache as ProspectFeedCaptureMetadataCache
          : null;
      if (metadataCache != null) {
        try {
          return parsed.withCapturedAt(
            await metadataCache.loadCapturedAt(raw),
          );
        } catch (_) {
          // A metadata read failure must not hide a valid cached feed.
        }
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  Future<ProspectFeedLoadResult?> _loadBundledFeed() async {
    try {
      final raw = await _bundledLoader();
      if (raw.trim().isEmpty) return null;
      return _parse(raw, fromCache: true);
    } catch (_) {
      return null;
    }
  }
}

ProspectFeedLoadResult parseProspectFeed(String raw, {bool fromCache = false}) {
  final json = jsonDecode(raw);
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Ungültiger Prospektfeed');
  }

  final generatedAt = DateTime.tryParse(
    _stringValue(json['generatedAt']) ?? '',
  );
  final capturedAt = DateTime.tryParse(
    _stringValue(json['capturedAt']) ?? '',
  );
  final sourceValues =
      _listValue(json['sources']);
  final refreshedStores = <String>[];
  final refreshedStoreScopes = <ProspectRefreshScope>[];
  final availableStores = <String>[...configuredProspectStores];
  final availableStoreUrls = <String, String>{};
  final sourceMetadataByIndex =
      List<_ProspectSourceMetadata?>.filled(sourceValues.length, null);
  final sourceEntriesByStore =
      <String, List<_ProspectSourceMetadata>>{};

  for (var sourceIndex = 0;
      sourceIndex < sourceValues.length;
      sourceIndex++) {
    final source = sourceValues[sourceIndex];
    if (source is! Map<String, dynamic>) continue;
    final storeName = _stringValue(source['storeName']);
    if (storeName == null || storeName.trim().isEmpty) continue;
    final storeKey = _prospectStoreMetadataKey(storeName);
    if (!availableStores.any(
      (entry) => _prospectStoreMetadataKey(entry) == storeKey,
    )) {
      availableStores.add(storeName);
    }
    final sourceUrl = _stringValue(source['url']);
    final sourceBranch = _prospectBranchContext(source);
    final branchId = sourceBranch.branchId;
    final location = sourceBranch.location;
    final address = sourceBranch.address;
    final sourceAdapter =
        _optionalNonEmptyString(source['sourceAdapter']) ??
        _optionalNonEmptyString(source['adapter']) ??
        _optionalNonEmptyString(source['mode']);
    final metadata = _ProspectSourceMetadata(
      storeName: storeName,
      url: sourceUrl,
      branchId: branchId,
      location: location,
      address: address,
      status: _stringValue(source['status']) ?? 'unknown',
      recordCount: _intValue(source['recordCount']) ?? 0,
      sourceAdapter: sourceAdapter,
    );
    sourceMetadataByIndex[sourceIndex] = metadata;
    sourceEntriesByStore
        .putIfAbsent(_prospectStoreMetadataKey(storeName), () => <_ProspectSourceMetadata>[])
        .add(metadata);
    if (sourceUrl != null && sourceUrl.trim().isNotEmpty) {
      availableStoreUrls[storeName] = sourceUrl;
    }
    if (metadata.status == 'ok') {
      final scope = ProspectRefreshScope(
        storeName: storeName,
        branchId: branchId,
      );
      if (!refreshedStoreScopes.any((entry) => entry.key == scope.key)) {
        refreshedStoreScopes.add(scope);
      }
      if (!refreshedStores.any(
        (entry) => _prospectStoreMetadataKey(entry) == storeKey,
      )) {
        // Keep the historical store-label projection for callers that do not
        // understand branch-aware scopes yet.
        refreshedStores.add(storeName);
      }
    }
  }

  _ProspectSourceMetadata? sourceMetadataForOffer(
    String storeName,
    String? branchId,
  ) {
    final entries =
        sourceEntriesByStore[_prospectStoreMetadataKey(storeName)];
    if (entries == null || entries.isEmpty) return null;
    final requestedBranchId = canonicalBranchId(branchId);
    if (requestedBranchId != null) {
      final matches = entries
          .where(
            (entry) =>
                canonicalBranchId(entry.branchId) == requestedBranchId,
          )
          .toList(growable: false);
      return matches.length == 1 ? matches.single : null;
    }
    // A store name alone is insufficient when the feed contains multiple
    // branches. Leave the record unscoped instead of assigning the last
    // source entry's branch and location.
    return entries.length == 1 ? entries.single : null;
  }

  String? sourceAdapterForOffer(String storeName, String? branchId) {
    final exact = sourceMetadataForOffer(storeName, branchId);
    final exactAdapter = exact?.sourceAdapter?.trim();
    if (exactAdapter != null && exactAdapter.isNotEmpty) {
      return exactAdapter;
    }
    final entries =
        sourceEntriesByStore[_prospectStoreMetadataKey(storeName)];
    if (entries == null || entries.isEmpty) return null;
    // Adapter provenance can remain unambiguous even when branch provenance
    // cannot. Preserve it so a branchless KaufDA record stays visibly regional
    // instead of looking like an unscoped first-party offer.
    final adapters = entries
        .map((entry) => entry.sourceAdapter?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    return adapters.length == 1 ? adapters.single : null;
  }


  final recordsByKey = <String, OfferImportRecord>{};
  // Indexes records by stable price/identity fields so a later copy can fill
  // missing EAN or package metadata without collapsing two known variants.
  final recordsByMergeKey = <String, List<String>>{};
  final prospects = <ProspectIssue>[];
  final pageImagesByStoreAndNumber =
      <String, List<_ProspectPageImageCandidate>>{};
  final sourceIndicesWithProspects = <int>{};
  for (var sourceIndex = 0;
      sourceIndex < sourceValues.length;
      sourceIndex++) {
    final source = sourceValues[sourceIndex];
    final sourceMetadata = sourceMetadataByIndex[sourceIndex];
    if (source is! Map<String, dynamic> || sourceMetadata == null) continue;
    final storeName = sourceMetadata.storeName;
    for (final raw in _listValue(source['prospects'])) {
      if (raw is! Map<String, dynamic>) continue;
      final pagesByNumber = <int, ProspectPage>{};
      for (final page in _listValue(raw['pageSamples'])) {
        if (page is! Map<String, dynamic>) continue;
        final image = _firstHttpUrl([
          page['image'],
          page['imageUrl'],
          page['thumbnailUrl'],
          page['url'],
        ]);
        final number = _intValue(page['number'] ?? page['pageNumber']);
        if (image == null || number == null || number < 1) continue;
        // A few public feed variants repeat the same page or emit samples
        // out of order. Keep one source page per positive number and sort it
        // deterministically for the viewer and cover fallback.
        pagesByNumber.putIfAbsent(
          number,
          () => ProspectPage(
            number: number,
            imageUrl: image,
            zoomUrl: _firstHttpUrl([
              page['zoom'],
              page['zoomUrl'],
              page['largeImageUrl'],
              page['fullImageUrl'],
            ]),
            keyWords: _stringValue(page['keyWords']) ??
                _stringValue(page['keywords']) ??
                _stringValue(page['altText']) ??
                '',
          ),
        );
      }
      final pages = pagesByNumber.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      // Keep metadata-only prospect entries as well. Some retailers publish
      // dates, branch context and an official link before they provide page
      // images; dropping those fields makes a current source look unknown.
      final issueValidFrom = DateTime.tryParse(
        _prospectDateText(
              _prospectValidityValue(raw, start: true),
            ) ??
            '',
      );
      final issueValidUntil = DateTime.tryParse(
        _prospectDateText(
              _prospectValidityValue(raw, start: false),
            ) ??
            '',
      );
      final rawBranch = _prospectBranchContext(raw);
      final rawBranchId = rawBranch.branchId;
      final rawLocation = rawBranch.location;
      final rawAddress = rawBranch.address;
      final rawBranchKey = canonicalBranchId(rawBranchId);
      final sourceBranchKey = canonicalBranchId(sourceMetadata.branchId);
      final inheritsSourceContext = rawBranchKey == null ||
          (sourceBranchKey != null && rawBranchKey == sourceBranchKey);
      final issueBranchId = rawBranchId ?? sourceMetadata.branchId;
      final issue = ProspectIssue(
        storeName: storeName,
        title: _stringValue(raw['title']) ?? 'Prospekt',
        pages: pages,
        url: _httpUrlValue(raw['url']),
        // Older source formats exposed only pageSamples. Reuse the first
        // already validated page as the cover instead of dropping a valid
        // image and rendering a misleading empty card.
        thumbnailUrl: _firstHttpUrl([
              raw['thumbnailUrl'],
              raw['coverUrl'],
              raw['coverImage'],
              raw['imageUrl'],
              raw['image'],
            ]) ??
            (pages.isEmpty ? null : pages.first.imageUrl),
        branchId: issueBranchId,
        location: rawLocation ??
            (inheritsSourceContext ? sourceMetadata.location : null),
        address: rawAddress ??
            (inheritsSourceContext ? sourceMetadata.address : null),
        sourceAdapter: sourceMetadata.sourceAdapter,
        sourceStatus: sourceMetadata.status,
        recordCount: sourceMetadata.recordCount,
        availablePageCount: _intValue(raw['availablePageCount']) ??
            (_boolValue(raw['pageCountKnown']) == false
                ? null
                : _intValue(raw['pageCount'])),
        loadedPageCount: _intValue(raw['loadedPageCount']) ?? pages.length,
        missingPageNumbers: _intList(raw['missingPageNumbers']),
        pageStatus: _stringValue(raw['pageStatus']) ?? 'unknown',
        pageCountKnown: _boolValue(raw['pageCountKnown']) ??
            raw['pageCount'] != null,
        uncertainProductCount: _intValue(raw['uncertainProductCount']),
        validFrom: issueValidFrom,
        validUntil: issueValidUntil,
      );
      prospects.add(issue);
      sourceIndicesWithProspects.add(sourceIndex);
      for (final page in pages) {
        pageImagesByStoreAndNumber
            .putIfAbsent(
              _prospectPageImageKey(storeName, page.number),
              () => <_ProspectPageImageCandidate>[],
            )
            .add(
              _ProspectPageImageCandidate(
                imageUrl: page.imageUrl,
                branchId: issue.branchId,
                validFrom: issueValidFrom,
                validUntil: issueValidUntil,
              ),
            );
      }
    }
  }
  // Keep one card per exact source entry. Two branches may share the
  // same retailer name, and collapsing them by store name would show the
  // wrong cover/location or hide one of the branches.
  final sourceStoreNames = <String>{};
  for (var sourceIndex = 0;
      sourceIndex < sourceMetadataByIndex.length;
      sourceIndex++) {
    final metadata = sourceMetadataByIndex[sourceIndex];
    if (metadata == null) continue;
    sourceStoreNames.add(
      _prospectStoreMetadataKey(metadata.storeName),
    );
    if (sourceIndicesWithProspects.contains(sourceIndex)) continue;
    prospects.add(
      ProspectIssue(
        storeName: metadata.storeName,
        title: 'Aktionsprospekt',
        pages: const <ProspectPage>[],
        url: officialProspectUrl(metadata.storeName, metadata.url),
        branchId: metadata.branchId,
        location: metadata.location,
        address: metadata.address,
        sourceAdapter: metadata.sourceAdapter,
        sourceStatus: metadata.status,
        recordCount: metadata.recordCount,
      ),
    );
  }
  // Jeder konfigurierte Markt bleibt in der Prospektansicht sichtbar, even
  // when the feed has no source entry at all.
  for (final storeName in availableStores) {
    if (sourceStoreNames.contains(
      _prospectStoreMetadataKey(storeName),
    )) {
      continue;
    }
    prospects.add(
      ProspectIssue(
        storeName: storeName,
        title: 'Aktionsprospekt',
        pages: const <ProspectPage>[],
        url: officialProspectUrl(storeName, availableStoreUrls[storeName]),
        sourceStatus: 'unavailable',
        recordCount: 0,
      ),
    );
  }


  for (final value in _listValue(json['offers'])) {
    if (value is! Map<String, dynamic>) continue;
    final sourceId = _stringValue(value['sourceId']);
    final productLabel = _stringValue(value['productLabel']);
    final storeName = _stringValue(value['storeName']);
    final offerPriceValue = value['offerPrice'];
    // Keep the source boundary strict: JSON numbers are accepted directly;
    // formatted strings need an explicit EUR/€ marker so arbitrary text or
    // locale-ambiguous numeric strings cannot become a price.
    final offerPrice = _offerPriceValue(offerPriceValue);
    final validUntilValue = _prospectValidityValue(value, start: false);
    final validUntilText = _prospectDateText(validUntilValue);
    final validUntil = DateTime.tryParse(validUntilText ?? '');
    final validFromValue = _prospectValidityValue(value, start: true);
    final validFromText = _prospectDateText(validFromValue);
    final validFrom = DateTime.tryParse(validFromText ?? '');
    final hasMalformedValidFrom = validFromValue != null &&
        (validFromText == null ||
            (validFromText.isNotEmpty && validFrom == null));
    final capturedAtValue = value['capturedAt'];
    final capturedAtText = _stringValue(capturedAtValue);
    final capturedAt = DateTime.tryParse(capturedAtText ?? '');
    final hasMalformedCapturedAt = capturedAtValue != null &&
        (capturedAtText == null ||
            (capturedAtText.isNotEmpty && capturedAt == null));
    final rawEan = _firstNonNullValue(
      value,
      const ['ean', 'gtin', 'barcode', 'productCode', 'product_code'],
    );
    final eanText = _sourceLabelValue(rawEan) ??
        (rawEan is num && !rawEan.isNaN ? rawEan.toString() : null);
    final ean = eanText == null ? null : normalizeBarcode(eanText);
    final hasMalformedEan = eanText != null && ean == null;
    if (sourceId == null ||
        sourceId.trim().isEmpty ||
        productLabel == null ||
        productLabel.trim().isEmpty ||
        storeName == null ||
        storeName.trim().isEmpty ||
        offerPrice == null ||
        !offerPrice.isFinite ||
        offerPrice <= 0 ||
        validUntil == null ||
        hasMalformedEan) {
      continue;
    }
    final category = _firstProspectCategoryLabel(
      value,
      const [
        'category',
        'categoryName',
        'category_name',
        'productCategory',
        'productCategories',
        'categories',
        'categoryPath',
        'category_path',
        'warengruppe',
        'sortiment',
      ],
    );
    final subcategory = _firstSourceLabel(
      value,
      const ['subcategory', 'subCategory', 'sub_category'],
    );
    final department = _firstSourceLabel(
      value,
      const ['department', 'departmentName', 'abteilung'],
    );
    if (!isFoodProspectRecord(
      label: productLabel,
      category: category,
      subcategory: subcategory,
      department: department,
    )) {
      continue;
    }
    // A malformed optional start date is not the same as an absent start
    // date. Treating it as absent could make an unverifiable offer appear
    // current and routeable. Reversed periods are equally unusable.
    if (hasMalformedValidFrom ||
        hasMalformedCapturedAt ||
        (validFrom != null && validUntil.isBefore(validFrom))) {
      continue;
    }

    // Public adapters normalize to originalPrice, but older/optional
    // sources have used explicit regular-price aliases. Accept only these
    // named fields; no discount, UVP or arbitrary numeric field is inferred.
    final originalPriceValue = _firstNonNullValue(
      value,
      const [
        'originalPrice',
        'streichpreis',
        'regularPrice',
        'normalPrice',
        'wasPrice',
        'wasPriceDisplay',
        'alterPreis',
        'oldPrice',
        'priceBefore',
        'previousPrice',
        'crossedOutPrice',
        'strikethroughPrice',
        'wasPriceNumeric',
        'original_price',
        'regular_price',
        'normal_price',
        'old_price',
        'previous_price',
        'crossed_out_price',
        'strikethrough_price',
      ],
    );
    final originalPrice = _priceValue(originalPriceValue);
    final explicitRegularPriceSource =
        _optionalNonEmptyString(value['regularPriceSource']);
    final inferredRegularPriceSource =
        _inferProspectRegularPriceSource(value);
    final rawRegularPriceSource =
        explicitRegularPriceSource ?? inferredRegularPriceSource;
    final regularPriceSource = originalPrice == null
        ? null
        : canonicalProspectRegularPriceSource(rawRegularPriceSource);
    final hasMalformedOriginalPrice = originalPriceValue != null &&
        (originalPrice == null ||
            !originalPrice.isFinite ||
            originalPrice <= 0);
    final hasMalformedRegularPriceSource = originalPrice != null &&
        rawRegularPriceSource != null &&
        regularPriceSource == null;
    if (hasMalformedOriginalPrice || hasMalformedRegularPriceSource) continue;
    final regionalOnlyValue = value['regionalOnly'];
    final parsedRegionalOnly = _boolValue(regionalOnlyValue);
    final explicitSourceAdapter = _optionalNonEmptyString(
      value['sourceAdapter'],
    );
    final brochurePage = _intValue(value['brochurePage']);
    final offerBranch = _prospectBranchContext(value);
    final explicitBranchId = offerBranch.branchId;
    final sourceFallback = sourceMetadataForOffer(
      storeName,
      explicitBranchId,
    );
    final sourceAdapter = explicitSourceAdapter ??
        sourceFallback?.sourceAdapter ??
        sourceAdapterForOffer(storeName, explicitBranchId);
    final isKaufdaWithoutBranch =
        sourceAdapter?.trim().toLowerCase() == 'kaufda' &&
        explicitBranchId == null;
    // A false/changed-format regional flag cannot promote a publisher-level
    // KaufDA hit to a branch price. The branch assertion must be present on
    // the record itself; source-level branch metadata is only a UI fallback.
    // This guard also applies when the adapter is inherited from the source
    // metadata; only an explicit record branch assertion can make a KaufDA
    // result routeable.
    final regionalOnly = isKaufdaWithoutBranch
        ? true
        : (parsedRegionalOnly ?? (regionalOnlyValue != null));
    final recordBranchId = regionalOnly
        ? explicitBranchId
        : (explicitBranchId ?? sourceFallback?.branchId);
    final productImageUrl = _firstHttpUrl([
      value['imageUrl'],
      value['imageURL'],
      value['image_url'],
      value['image'],
      value['images'],
      value['imageUrls'],
      value['productImage'],
      value['productImages'],
      value['product_image'],
      value['media'],
      value['assets'],
      value['bild'],
      value['bild_app'],
      value['bild_web130'],
      value['bild_web90'],
    ]);
    final pageImageUrl = productImageUrl == null
        ? _prospectPageImageForOffer(
            pageImagesByStoreAndNumber,
            storeName: storeName,
            branchId: recordBranchId,
            pageNumber: brochurePage,
            validFrom: validFrom,
            validUntil: validUntil,
          )
        : null;
    final record = OfferImportRecord(
        sourceId: sourceId,
        productLabel: productLabel,
        storeName: storeName,
        ean: ean,
        originalPrice: originalPrice,
        regularPriceSource: regularPriceSource,
        offerPrice: offerPrice,
        validFrom: validFrom,
        validUntil: validUntil,
        source: _stringValue(value['source']) ?? 'retailerWebsite',
        proofRef: _stringValue(value['proofRef']),
        imageUrl: productImageUrl ?? pageImageUrl,
        imageKind: productImageUrl != null
            ? ProspectImageKind.product
            : pageImageUrl != null
            ? ProspectImageKind.prospectPage
            : null,
        category: category,
        packageSize: _firstSourceLabel(
          value,
          const ['packageSize', 'package', 'packaging', 'quantityLabel'],
        ),
        priceByBaseUnit: _firstSourceLabel(
          value,
          const ['priceByBaseUnit', 'unitPrice', 'baseUnitPrice'],
        ),
        sourceAdapter: sourceAdapter,
        // An unknown explicit regional flag is treated conservatively. It
        // remains visible as diagnostic evidence but cannot become routeable.
        regionalOnly: regionalOnly,
        brochureId: _stringValue(value['brochureId']),
        brochurePage: brochurePage,
        publisherId: _stringValue(value['publisherId']),
        capturedAt: capturedAt,
        branchId: recordBranchId,
        location: regionalOnly
            ? offerBranch.location
            : (offerBranch.location ?? sourceFallback?.location),
        address: regionalOnly
            ? offerBranch.address
            : (offerBranch.address ?? sourceFallback?.address),
      );
    final key = _prospectRecordKey(record);
    final previous = recordsByKey[key];
    if (previous != null) {
      recordsByKey[key] = _mergeProspectRecordMetadata(previous, record);
      continue;
    }

    final mergeKey = _prospectRecordMergeKey(record);
    final candidates = recordsByMergeKey[mergeKey];
    final compatibleKeys = candidates
        ?.where((candidateKey) {
          final candidate = recordsByKey[candidateKey];
          return candidate != null &&
              _prospectRecordsCanMergeMetadata(candidate, record);
        })
        .toList(growable: false);
    // Merge a metadata-only variant only when the bucket has one unambiguous
    // compatible row. If two package/EAN variants are present, an incomplete
    // row remains separate instead of being assigned to the wrong variant.
    if (compatibleKeys != null && compatibleKeys.length == 1) {
      final candidateKey = compatibleKeys.single;
      final candidate = recordsByKey.remove(candidateKey);
      if (candidate != null) {
        final merged = _mergeProspectRecordMetadata(candidate, record);
        final mergedKey = _prospectRecordKey(merged);
        recordsByKey[mergedKey] = merged;
        final candidateIndex = candidates!.indexOf(candidateKey);
        if (candidateIndex >= 0) {
          candidates[candidateIndex] = mergedKey;
        }
        continue;
      }
    }

    recordsByKey[key] = record;
    recordsByMergeKey.putIfAbsent(mergeKey, () => <String>[]).add(key);
  }

  final records = recordsByKey.values.toList(growable: false);

  return ProspectFeedLoadResult(
    records: records,
    refreshedStores: refreshedStores,
    refreshedStoreScopes: refreshedStoreScopes,
    generatedAt: generatedAt,
    capturedAt: capturedAt,
    prospects: prospects,
    fromCache: fromCache,
  );
}

String _prospectRecordMergeKey(OfferImportRecord record) {
  final fields = <String>[
    record.storeName,
    record.branchId ?? '',
    record.sourceAdapter ?? '',
    record.sourceId,
    record.productLabel,
    record.offerPrice.toStringAsFixed(4),
    record.originalPrice?.toStringAsFixed(4) ?? '',
    record.validFrom?.toIso8601String() ?? '',
    record.validUntil.toIso8601String(),
  ];
  return fields
      .map((value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
      .join('\u001f');
}

bool _prospectMetadataValueCompatible(String? first, String? second) {
  final normalizedFirst =
      first?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final normalizedSecond =
      second?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return normalizedFirst == null ||
      normalizedFirst.isEmpty ||
      normalizedSecond == null ||
      normalizedSecond.isEmpty ||
      normalizedFirst == normalizedSecond;
}

bool _prospectRecordsCanMergeMetadata(
  OfferImportRecord first,
  OfferImportRecord second,
) {
  return _prospectMetadataValueCompatible(first.ean, second.ean) &&
      _prospectMetadataValueCompatible(first.packageSize, second.packageSize);
}

String? _preferProspectText(String? first, String? second) {
  if (first?.trim().isNotEmpty == true) return first;
  if (second?.trim().isNotEmpty == true) return second;
  return null;
}

/// Keeps one conservative price/identity row while retaining richer optional
/// evidence from a later identical source copy. Price, validity, branch and
/// source identity stay anchored to the first record.
OfferImportRecord _mergeProspectRecordMetadata(
  OfferImportRecord first,
  OfferImportRecord second,
) {
  final firstHasImage = first.imageUrl?.trim().isNotEmpty == true;
  final secondHasImage = second.imageUrl?.trim().isNotEmpty == true;
  final preferSecondImage = secondHasImage &&
      (!firstHasImage ||
          (second.imageKind == ProspectImageKind.product &&
              first.imageKind != ProspectImageKind.product));
  final mergedImage = preferSecondImage
      ? second.imageUrl
      : _preferProspectText(first.imageUrl, second.imageUrl);
  final mergedImageKind = preferSecondImage
      ? second.imageKind
      : (first.imageKind ?? second.imageKind);
  final mergedCapturedAt = first.capturedAt == null
      ? second.capturedAt
      : second.capturedAt == null
      ? first.capturedAt
      : second.capturedAt!.isAfter(first.capturedAt!)
      ? second.capturedAt
      : first.capturedAt;

  return OfferImportRecord(
    sourceId: first.sourceId,
    productLabel: first.productLabel,
    storeName: first.storeName,
    originalPrice: first.originalPrice,
    offerPrice: first.offerPrice,
    validUntil: first.validUntil,
    validFrom: first.validFrom,
    source: first.source,
    proofRef: _preferProspectText(first.proofRef, second.proofRef),
    imageUrl: mergedImage,
    imageKind: mergedImageKind,
    ean: _preferProspectText(first.ean, second.ean),
    category: _preferProspectText(first.category, second.category),
    packageSize: _preferProspectText(first.packageSize, second.packageSize),
    priceByBaseUnit:
        _preferProspectText(first.priceByBaseUnit, second.priceByBaseUnit),
    regularPriceSource: _preferProspectText(
      first.regularPriceSource,
      second.regularPriceSource,
    ),
    sourceAdapter:
        _preferProspectText(first.sourceAdapter, second.sourceAdapter),
    regionalOnly: first.regionalOnly && second.regionalOnly,
    brochureId: _preferProspectText(first.brochureId, second.brochureId),
    brochurePage: first.brochurePage ?? second.brochurePage,
    publisherId: _preferProspectText(first.publisherId, second.publisherId),
    capturedAt: mergedCapturedAt,
    branchId: _preferProspectText(first.branchId, second.branchId),
    location: _preferProspectText(first.location, second.location),
    address: _preferProspectText(first.address, second.address),
  );
}

String? _inferProspectRegularPriceSource(Map<String, dynamic> value) {
  const keys = <String>[
    'originalPrice',
    'streichpreis',
    'regularPrice',
    'normalPrice',
    'wasPrice',
    'wasPriceDisplay',
    'alterPreis',
    'oldPrice',
    'priceBefore',
    'previousPrice',
    'crossedOutPrice',
    'strikethroughPrice',
    'wasPriceNumeric',
    'original_price',
    'regular_price',
    'normal_price',
    'old_price',
    'previous_price',
    'crossed_out_price',
    'strikethrough_price',
    'secondaryPrice',
    'spare',
  ];
  for (final key in keys) {
    if (value[key] != null) return key;
  }
  return null;
}

String _prospectPageImageKey(String storeName, int pageNumber) =>
    '${_prospectStoreMetadataKey(storeName)}\\u001f$pageNumber';

String? _prospectPageImageForOffer(
  Map<String, List<_ProspectPageImageCandidate>> pagesByStoreAndNumber, {
  required String storeName,
  required String? branchId,
  required int? pageNumber,
  required DateTime? validFrom,
  required DateTime validUntil,
}) {
  if (pageNumber == null) return null;
  final candidates =
      pagesByStoreAndNumber[_prospectPageImageKey(storeName, pageNumber)];
  if (candidates == null || candidates.isEmpty) return null;
  final normalizedBranchId = canonicalBranchId(branchId);
  if (normalizedBranchId == null) return null;
  for (final candidate in candidates) {
    if (canonicalBranchId(candidate.branchId) != normalizedBranchId) continue;
    final startsAfterOffer =
        candidate.validFrom != null && candidate.validFrom!.isAfter(validUntil);
    final endsBeforeOffer =
        candidate.validUntil != null &&
        validFrom != null &&
        candidate.validUntil!.isBefore(validFrom);
    if (!startsAfterOffer && !endsBeforeOffer) return candidate.imageUrl;
  }
  // A branch mismatch must stay unknown even when only one page candidate
  // exists. Never fall back across an asserted store boundary.
  return null;
}

String _prospectRecordKey(OfferImportRecord record) {
  // Feed publishers occasionally repeat the same article on multiple
  // brochure pages. Keep the key conservative: a changed branch, package,
  // amount, regular price or validity is a distinct observation.
  final fields = <String>[
    record.storeName,
    record.branchId ?? '',
    record.sourceAdapter ?? '',
    record.sourceId,
    record.productLabel,
    record.ean ?? '',
    record.packageSize ?? '',
    record.offerPrice.toStringAsFixed(4),
    record.originalPrice?.toStringAsFixed(4) ?? '',
    record.validFrom?.toIso8601String() ?? '',
    record.validUntil.toIso8601String(),
  ];
  return fields
      .map((value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
      .join('\u001f');
}

Object? _firstNonNullValue(
  Map<String, dynamic> value,
  Iterable<String> keys,
) {
  for (final key in keys) {
    final candidate = value[key];
    if (candidate != null) return candidate;
  }
  return null;
}

String? _stringValue(Object? value) => value is String ? value.trim() : null;

/// Parses the strict price formats used by German retailer feeds.
///
/// A regular-price field may arrive as a JSON number or as a display value
/// such as `7,99 €`. Free-form labels like `UVP 7,99 €` are rejected so a
/// descriptive text cannot become a false price observation.
double? _priceValue(Object? value) {
  if (value is num) {
    final number = value.toDouble();
    return number.isFinite ? number : null;
  }
  if (value is Map) {
    // Follow only bounded, explicitly named price fields. IDs, URLs and
    // arbitrary nested numbers are never interpreted as money.
    for (final key in const [
      'amount',
      'value',
      'numeric',
      'number',
      'price',
      'formatted',
      'formattedPrice',
      'priceText',
      'display',
    ]) {
      final parsed = _priceValue(value[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }
  if (value is! String) return null;
  var compact = value
      .replaceAll('\u00a0', '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
  if (compact.isEmpty) return null;
  final currencyPrefix = RegExp(r'^(?:€|EUR)', caseSensitive: false);
  if (currencyPrefix.matchAsPrefix(compact) != null) {
    compact = compact.replaceFirst(currencyPrefix, '');
  }
  final uppercase = compact.toUpperCase();
  if (uppercase.endsWith('EUR')) {
    compact = compact.substring(0, compact.length - 3);
  } else if (compact.endsWith('€')) {
    compact = compact.substring(0, compact.length - 1);
  }
  if (compact.isEmpty) return null;
  final simple = RegExp(r'^\d+(?:[.,]\d{1,2})?');
  final grouped = RegExp(r'^\d{1,3}(?:\.\d{3})+,\d{1,2}');
  final isSimple = simple.matchAsPrefix(compact)?.end == compact.length;
  final isGrouped = grouped.matchAsPrefix(compact)?.end == compact.length;
  if (!isSimple && !isGrouped) return null;
  final normalized = compact.contains(',')
      ? compact.replaceAll('.', '').replaceFirst(',', '.')
      : compact;
  final number = double.tryParse(normalized);
  return number != null && number.isFinite ? number : null;
}

bool _hasCurrencyMarker(String value) =>
    RegExp(r'(?:€|\bEUR\b)', caseSensitive: false).hasMatch(value);

/// Offer prices may arrive as a localized display string or a small named
/// price object. A plain numeric string remains invalid by design.
double? _offerPriceValue(Object? value) {
  if (value is num || value is Map) return _priceValue(value);
  if (value is! String || !_hasCurrencyMarker(value)) return null;
  return _priceValue(value);
}

String? _firstHttpUrl(
  Iterable<Object?> values, {
  int depth = 0,
}) {
  if (depth > 2) return null;
  for (final value in values) {
    final url = _httpUrlValue(value);
    if (url != null) return url;
    if (value is List) {
      // Public feed variants sometimes wrap product images in a short
      // ordered list. Traverse only the bounded image container; arbitrary
      // nested JSON is never interpreted as a URL.
      for (final item in value) {
        final nested = _firstHttpUrl([item], depth: depth + 1);
        if (nested != null) return nested;
      }
      continue;
    }
    if (value is Map) {
      final nested = _firstHttpUrl(
        [
          value['url'],
          value['src'],
          value['href'],
          value['imageUrl'],
          value['imageURL'],
          value['image_url'],
          value['image'],
          value['images'],
          value['imageUrls'],
          value['productImages'],
          value['media'],
          value['assets'],
          value['thumbnail'],
          value['thumbnailUrl'],
          value['thumbnails'],
          value['cover'],
          value['coverUrl'],
          value['coverImage'],
          value['coverImageUrl'],
          value['original'],
          value['originalUrl'],
          value['large'],
          value['largeUrl'],
        ],
        depth: depth + 1,
      );
      if (nested != null) return nested;
    }
  }
  return null;
}

String? _prospectCategoryLabel(Object? value, {int depth = 0}) {
  if (depth > 2) return null;
  final direct = _sourceLabelValue(value);
  if (direct != null) return direct;
  if (value is List) {
    final labels = <String>[];
    for (final item in value) {
      final label = _prospectCategoryLabel(item, depth: depth + 1);
      if (label == null || labels.contains(label)) continue;
      labels.add(label);
      if (labels.length == 3) break;
    }
    return labels.isEmpty ? null : labels.join(' / ');
  }
  if (value is Map) {
    for (final key in const [
      'category',
      'categories',
      'categoryPath',
      'category_path',
      'items',
      'path',
    ]) {
      final nested = _prospectCategoryLabel(value[key], depth: depth + 1);
      if (nested != null) return nested;
    }
  }
  return null;
}

String? _firstProspectCategoryLabel(
  Map<String, dynamic> value,
  Iterable<String> keys,
) {
  for (final key in keys) {
    final label = _prospectCategoryLabel(value[key]);
    if (label != null) return label;
  }
  return null;
}

String? _firstSourceLabel(
  Map<String, dynamic> value,
  Iterable<String> keys,
) {
  for (final key in keys) {
    final label = _sourceLabelValue(value[key]);
    if (label != null) return label;
  }
  return null;
}

String? _sourceLabelValue(Object? value, {int depth = 0}) {
  if (depth > 2) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is Map) {
    for (final key in const ['name', 'title', 'label', 'value']) {
      final nested = _sourceLabelValue(value[key], depth: depth + 1);
      if (nested != null) return nested;
    }
  }
  return null;
}

String? _httpUrlValue(Object? value) {
  final raw = _stringValue(value);
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      uri.host.trim().isEmpty ||
      (scheme != 'http' && scheme != 'https')) {
    return null;
  }
  return raw;
}

int? _intValue(Object? value) {
  if (value is num && value.isFinite) return value.toInt();
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

List<int> _intList(Object? value) {
  if (value is! List) return const <int>[];
  final result = <int>{};
  for (final item in value) {
    final number = _intValue(item);
    if (number != null && number > 0) result.add(number);
  }
  return result.toList()..sort();
}

bool? _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
    return null;
  }
  if (value is! String) return null;
  switch (value.trim().toLowerCase()) {
    case 'true':
    case '1':
    case 'yes':
      return true;
    case 'false':
    case '0':
    case 'no':
      return false;
    default:
      return null;
  }
}

