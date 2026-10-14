import 'dart:convert';

import 'package:flutter/services.dart';
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
  r'katzenfutter|tiernahrung'
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

String? _optionalNonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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
  Future<ProspectFeedLoadResult?> loadCached() async {
    final cached = await _loadCachedFeed();
    if (cached != null) return cached;
    return _loadBundledFeed();
  }

  Future<ProspectFeedLoadResult> _loadNow() async {
    if (!networkEnabled) {
      final cached = await _loadCachedFeed();
      if (cached != null) return cached;
      final bundled = await _loadBundledFeed();
      if (bundled != null) return bundled;
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
      final bundled = await _loadBundledFeed();
      if (bundled != null) return bundled;
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

  Future<ProspectFeedLoadResult?> _loadBundledFeed() async {
    try {
      final raw = await _bundledLoader();
      if (raw.trim().isEmpty) return null;
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

  final generatedAt = DateTime.tryParse(
    _stringValue(json['generatedAt']) ?? '',
  );
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
    final storeName = _stringValue(source['storeName']);
    if (storeName == null || storeName.trim().isEmpty) continue;
    if (!availableStores.contains(storeName)) {
      availableStores.add(storeName);
    }
    sourceStatuses[storeName] = _stringValue(source['status']) ?? 'unknown';
    sourceRecordCounts[storeName] = _intValue(source['recordCount']) ?? 0;
    final sourceUrl = _stringValue(source['url']);
    if (sourceUrl != null && sourceUrl.trim().isNotEmpty) {
      availableStoreUrls[storeName] = sourceUrl;
    }
    final branchId = _stringValue(source['branchId']);
    if (branchId != null && branchId.trim().isNotEmpty) {
      sourceBranchIds[storeName] = branchId;
    }
    final location = _stringValue(source['location']);
    if (location != null && location.trim().isNotEmpty) {
      sourceLocations[storeName] = location;
    }
    final address = _stringValue(source['address']);
    if (address != null && address.trim().isNotEmpty) {
      sourceAddresses[storeName] = address;
    }
    if ((_stringValue(source['status']) ?? '') == 'ok' &&
        !refreshedStores.contains(storeName)) {
      refreshedStores.add(storeName);
    }
  }

  final recordsByKey = <String, OfferImportRecord>{};
  final prospects = <ProspectIssue>[];
  for (final source in (json['sources'] as List<dynamic>? ?? const [])) {
    if (source is! Map<String, dynamic>) continue;
    final storeName = _stringValue(source['storeName']);
    for (final raw in (source['prospects'] as List<dynamic>? ?? const [])) {
      if (storeName == null || raw is! Map<String, dynamic>) continue;
      final pagesByNumber = <int, ProspectPage>{};
      for (final page in (raw['pageSamples'] as List<dynamic>? ?? const [])) {
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
      prospects.add(
        ProspectIssue(
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
          branchId:
              _optionalNonEmptyString(raw['branchId']) ??
              sourceBranchIds[storeName],
          location:
              _optionalNonEmptyString(raw['location']) ??
              sourceLocations[storeName],
          address:
              _optionalNonEmptyString(raw['address']) ??
              sourceAddresses[storeName],
          sourceStatus: sourceStatuses[storeName] ?? 'unknown',
          recordCount: sourceRecordCounts[storeName] ?? 0,
          validFrom: DateTime.tryParse(
            _stringValue(raw['offerStartDate']) ??
                _stringValue(raw['startDate']) ??
                '',
          ),
          validUntil: DateTime.tryParse(
            _stringValue(raw['offerEndDate']) ??
                _stringValue(raw['endDate']) ??
                '',
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
    final capturedAtValue = value['capturedAt'];
    final capturedAtText = _stringValue(capturedAtValue);
    final capturedAt = DateTime.tryParse(capturedAtText ?? '');
    final hasMalformedCapturedAt = capturedAtValue != null &&
        (capturedAtText == null ||
            (capturedAtText.isNotEmpty && capturedAt == null));
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
    if (!isFoodProspectRecord(
      label: productLabel,
      category: _stringValue(value['category']),
      subcategory: _stringValue(value['subcategory']),
      department: _stringValue(value['department']),
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

    final originalPriceValue = value['originalPrice'];
    final originalPrice = originalPriceValue is num
        ? originalPriceValue.toDouble()
        : null;
    final hasMalformedOriginalPrice = originalPriceValue != null &&
        (originalPrice == null ||
            !originalPrice.isFinite ||
            originalPrice <= 0);
    if (hasMalformedOriginalPrice) continue;
    final regionalOnlyValue = value['regionalOnly'];
    final parsedRegionalOnly = _boolValue(regionalOnlyValue);
    final sourceAdapter = _stringValue(value['sourceAdapter']);
    final explicitBranchId = _optionalNonEmptyString(value['branchId']);
    final isKaufdaWithoutBranch =
        sourceAdapter?.trim().toLowerCase() == 'kaufda' &&
        explicitBranchId == null;
    // A false/changed-format regional flag cannot promote a publisher-level
    // KaufDA hit to a branch price. The branch assertion must be present on
    // the record itself; source-level branch metadata is only a UI fallback.
    final regionalOnly = isKaufdaWithoutBranch
        ? true
        : (parsedRegionalOnly ?? (regionalOnlyValue != null));
    final record = OfferImportRecord(
        sourceId: sourceId,
        productLabel: productLabel,
        storeName: storeName,
        originalPrice: originalPrice,
        offerPrice: offerPrice,
        validFrom: validFrom,
        validUntil: validUntil,
        source: _stringValue(value['source']) ?? 'retailerWebsite',
        proofRef: _stringValue(value['proofRef']),
        imageUrl: _httpUrlValue(value['imageUrl']),
        category: _stringValue(value['category']),
        packageSize: _stringValue(value['packageSize']),
        priceByBaseUnit: _stringValue(value['priceByBaseUnit']),
        sourceAdapter: sourceAdapter,
        // An unknown explicit regional flag is treated conservatively. It
        // remains visible as diagnostic evidence but cannot become routeable.
        regionalOnly: regionalOnly,
        brochureId: _stringValue(value['brochureId']),
        brochurePage: _intValue(value['brochurePage']),
        publisherId: _stringValue(value['publisherId']),
        capturedAt: capturedAt,
        branchId: regionalOnly
            ? explicitBranchId
            : (explicitBranchId ?? sourceBranchIds[storeName]),
        location: regionalOnly
            ? _optionalNonEmptyString(value['location'])
            : (_optionalNonEmptyString(value['location']) ??
                sourceLocations[storeName]),
        address: regionalOnly
            ? _optionalNonEmptyString(value['address'])
            : (_optionalNonEmptyString(value['address']) ??
                sourceAddresses[storeName]),
      );
    final key = _prospectRecordKey(record);
    recordsByKey.putIfAbsent(key, () => record);
  }

  final records = recordsByKey.values.toList(growable: false);

  return ProspectFeedLoadResult(
    records: records,
    refreshedStores: refreshedStores,
    generatedAt: generatedAt,
    prospects: prospects,
    fromCache: fromCache,
  );
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

String? _stringValue(Object? value) => value is String ? value.trim() : null;

String? _firstHttpUrl(Iterable<Object?> values) {
  for (final value in values) {
    final url = _httpUrlValue(value);
    if (url != null) return url;
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

