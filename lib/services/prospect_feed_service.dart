import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/offers/offer_import.dart';
import 'prospect_feed_cache.dart';

class ProspectFeedLoadResult {
  const ProspectFeedLoadResult({
    required this.records,
    required this.refreshedStores,
    this.generatedAt,
    this.prospects = const <ProspectIssue>[],
    this.fromCache = false,
  });

  final List<OfferImportRecord> records;
  final List<String> refreshedStores;
  final DateTime? generatedAt;
  final List<ProspectIssue> prospects;
  final bool fromCache;
}

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
    this.sourceStatus = 'unknown',
    this.recordCount = 0,
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
  final String sourceStatus;
  final int recordCount;
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

class ProspectFeedService {
  ProspectFeedService({http.Client? client, ProspectFeedCache? cache})
    : _client = client ?? http.Client(),
      _cache = cache ?? SharedPreferencesProspectFeedCache();

  static const feedUrl =
      'https://raw.githubusercontent.com/bndkxbqf2g-stack/SparzamApp/'
      'main/assets/prospects/current.json';

  final http.Client _client;
  final ProspectFeedCache _cache;

  Future<ProspectFeedLoadResult> load() async {
    try {
      final response = await _client
          .get(Uri.parse(feedUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Prospektfeed HTTP ${response.statusCode}');
      }
      final result = parseProspectFeed(response.body);
      // A cache failure must never hide a valid live feed.
      try {
        await _cache.save(response.body);
      } catch (_) {
        // The next online refresh can try to repair the cache.
      }
      return result;
    } catch (error, stackTrace) {
      final cached = await _loadCachedFeed();
      if (cached != null) return cached;
      Error.throwWithStackTrace(error, stackTrace);
    }
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
      return parseProspectFeed(raw, fromCache: true);
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

  final generatedAt = DateTime.tryParse(json['generatedAt'] as String? ?? '');
  final refreshedStores = <String>[];
  final availableStores = <String>[...configuredProspectStores];
  final availableStoreUrls = <String, String>{};
  final sourceBranchIds = <String, String>{};
  final sourceLocations = <String, String>{};
  final sourceAddresses = <String, String>{};
  final sourceStatuses = <String, String>{};
  final sourceRecordCounts = <String, int>{};
  for (final source in (json['sources'] as List<dynamic>? ?? const [])) {
    if (source is! Map<String, dynamic>) continue;
    final storeName = source['storeName'] as String?;
    if (storeName == null || storeName.trim().isEmpty) continue;
    if (!availableStores.contains(storeName)) {
      availableStores.add(storeName);
    }
    sourceStatuses[storeName] = source['status'] as String? ?? 'unknown';
    sourceRecordCounts[storeName] =
        (source['recordCount'] as num?)?.toInt() ?? 0;
    final sourceUrl = source['url'] as String?;
    if (sourceUrl != null && sourceUrl.trim().isNotEmpty) {
      availableStoreUrls[storeName] = sourceUrl;
    }
    final branchId = source['branchId'] as String?;
    if (branchId != null && branchId.trim().isNotEmpty) {
      sourceBranchIds[storeName] = branchId;
    }
    final location = source['location'] as String?;
    if (location != null && location.trim().isNotEmpty) {
      sourceLocations[storeName] = location;
    }
    final address = source['address'] as String?;
    if (address != null && address.trim().isNotEmpty) {
      sourceAddresses[storeName] = address;
    }
    if (source['status'] == 'ok' && !refreshedStores.contains(storeName)) {
      refreshedStores.add(storeName);
    }
  }

  final records = <OfferImportRecord>[];
  final prospects = <ProspectIssue>[];
  for (final source in (json['sources'] as List<dynamic>? ?? const [])) {
    if (source is! Map<String, dynamic>) continue;
    final storeName = source['storeName'] as String?;
    for (final raw in (source['prospects'] as List<dynamic>? ?? const [])) {
      if (storeName == null || raw is! Map<String, dynamic>) continue;
      final pages = <ProspectPage>[];
      for (final page in (raw['pageSamples'] as List<dynamic>? ?? const [])) {
        if (page is! Map<String, dynamic>) continue;
        final image = page['image'] as String?;
        final number = (page['number'] as num?)?.toInt();
        if (image != null && number != null) {
          pages.add(
            ProspectPage(
              number: number,
              imageUrl: image,
              zoomUrl: page['zoom'] as String?,
              keyWords: page['keyWords'] as String? ?? '',
            ),
          );
        }
      }
      // Keep metadata-only prospect entries as well. Some retailers publish
      // dates, branch context and an official link before they provide page
      // images; dropping those fields makes a current source look unknown.
      prospects.add(
        ProspectIssue(
          storeName: storeName,
          title: raw['title'] as String? ?? 'Prospekt',
          pages: pages,
          url: raw['url'] as String?,
          thumbnailUrl: raw['thumbnailUrl'] as String?,
          branchId: sourceBranchIds[storeName],
          location: sourceLocations[storeName],
          address: sourceAddresses[storeName],
          sourceStatus: sourceStatuses[storeName] ?? 'unknown',
          recordCount: sourceRecordCounts[storeName] ?? 0,
          validFrom: DateTime.tryParse(
            raw['offerStartDate'] as String? ??
                raw['startDate'] as String? ??
                '',
          ),
          validUntil: DateTime.tryParse(
            raw['offerEndDate'] as String? ?? raw['endDate'] as String? ?? '',
          ),
        ),
      );
    }
  }
  // Jeder konfigurierte Markt bleibt in der Prospektansicht sichtbar.
  // Einige Händler liefern aktuell nur strukturierte Angebote oder Metadaten,
  // aber noch keine Bildseiten. Für diese Märkte zeigt die App eine
  // informative Platzhalterkarte.
  final storesWithProspects = prospects.map((issue) => issue.storeName).toSet();
  for (final storeName in availableStores) {
    if (!storesWithProspects.contains(storeName)) {
      prospects.add(
        ProspectIssue(
          storeName: storeName,
          title: 'Aktionsprospekt',
          pages: const <ProspectPage>[],
          url: officialProspectUrl(storeName, availableStoreUrls[storeName]),
          branchId: sourceBranchIds[storeName],
          location: sourceLocations[storeName],
          address: sourceAddresses[storeName],
          sourceStatus: sourceStatuses[storeName] ?? 'unavailable',
          recordCount: sourceRecordCounts[storeName] ?? 0,
        ),
      );
    }
  }

  for (final value in (json['offers'] as List<dynamic>? ?? const [])) {
    if (value is! Map<String, dynamic>) continue;
    final sourceId = _stringValue(value['sourceId']);
    final productLabel = _stringValue(value['productLabel']);
    final storeName = _stringValue(value['storeName']);
    final offerPriceValue = value['offerPrice'];
    final offerPrice = offerPriceValue is num
        ? offerPriceValue.toDouble()
        : null;
    final validUntilValue = value['validUntil'];
    final validUntilText = _stringValue(validUntilValue);
    final validUntil = DateTime.tryParse(validUntilText ?? '');
    final validFromValue = value['validFrom'];
    final validFromText = _stringValue(validFromValue);
    final validFrom = DateTime.tryParse(validFromText ?? '');
    final hasMalformedValidFrom = validFromValue != null &&
        (validFromText == null ||
            (validFromText.isNotEmpty && validFrom == null));
    if (sourceId == null ||
        sourceId.trim().isEmpty ||
        productLabel == null ||
        productLabel.trim().isEmpty ||
        storeName == null ||
        storeName.trim().isEmpty ||
        offerPrice == null ||
        !offerPrice.isFinite ||
        offerPrice <= 0 ||
        validUntil == null) {
      continue;
    }
    // A malformed optional start date is not the same as an absent start
    // date. Treating it as absent could make an unverifiable offer appear
    // current and routeable. Reversed periods are equally unusable.
    if (hasMalformedValidFrom ||
        (validFrom != null && validUntil.isBefore(validFrom))) {
      continue;
    }

    final originalPriceValue = value['originalPrice'];
    final originalPrice = originalPriceValue is num
        ? originalPriceValue.toDouble()
        : null;
    final hasMalformedOriginalPrice = originalPriceValue != null &&
        (originalPrice == null || !originalPrice.isFinite || originalPrice <= 0);
    if (hasMalformedOriginalPrice) continue;
    records.add(
      OfferImportRecord(
        sourceId: sourceId,
        productLabel: productLabel,
        storeName: storeName,
        originalPrice: originalPrice,
        offerPrice: offerPrice,
        validFrom: validFrom,
        validUntil: validUntil,
        source: _stringValue(value['source']) ?? 'retailerWebsite',
        proofRef: _stringValue(value['proofRef']),
        imageUrl: _stringValue(value['imageUrl']),
        category: _stringValue(value['category']),
      ),
    );
  }

  return ProspectFeedLoadResult(
    records: records,
    refreshedStores: refreshedStores,
    generatedAt: generatedAt,
    prospects: prospects,
    fromCache: fromCache,
  );
}

String? _stringValue(Object? value) => value is String ? value.trim() : null;
