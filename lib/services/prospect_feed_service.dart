import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../features/offers/offer_import.dart';
import 'barcode_normalizer.dart';
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

String _prospectStoreMetadataKey(String value) => value.trim().toLowerCase();

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
      final result = _parse(response.body, fromCache: false);
      // A CDN or a temporarily stale publisher response must not replace a
      // newer validated local snapshot. Equal timestamps still prefer the
      // successful live response.
      final selected = _newestFeed(
        result,
        await _loadNewestLocalFeed(),
      )!;
      if (identical(selected, result)) {
        // A cache failure must never hide a valid live feed.
        try {
          await _cache.save(response.body);
        } catch (_) {
          // The next online refresh can try to repair the cache.
        }
      }
      return selected;
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
  /// cannot hide the newer asset.
  Future<ProspectFeedLoadResult?> _loadNewestLocalFeed() async {
    final local = await Future.wait<ProspectFeedLoadResult?>([
      _loadCachedFeed(),
      _loadBundledFeed(),
    ]);
    return _newestFeed(local[0], local[1]);
  }

  ProspectFeedLoadResult? _newestFeed(
    ProspectFeedLoadResult? first,
    ProspectFeedLoadResult? second,
  ) {
    if (first == null) return second;
    if (second == null) return first;

    final firstAt = first.generatedAt;
    final secondAt = second.generatedAt;
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
      return _parse(raw, fromCache: true);
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
  final sourceValues =
      json['sources'] as List<dynamic>? ?? const <dynamic>[];
  final refreshedStores = <String>[];
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
    final branchId = _optionalNonEmptyString(source['branchId']);
    final location = _optionalNonEmptyString(source['location']);
    final address = _optionalNonEmptyString(source['address']);
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
    if (metadata.status == 'ok' &&
        !refreshedStores.any(
          (entry) => _prospectStoreMetadataKey(entry) == storeKey,
        )) {
      refreshedStores.add(storeName);
    }
  }

  _ProspectSourceMetadata? sourceMetadataForOffer(
    String storeName,
    String? branchId,
  ) {
    final entries =
        sourceEntriesByStore[_prospectStoreMetadataKey(storeName)];
    if (entries == null || entries.isEmpty) return null;
    if (branchId != null) {
      final matches = entries
          .where((entry) => entry.branchId == branchId)
          .toList(growable: false);
      return matches.length == 1 ? matches.single : null;
    }
    // A store name alone is insufficient when the feed contains multiple
    // branches. Leave the record unscoped instead of assigning the last
    // source entry's branch and location.
    return entries.length == 1 ? entries.single : null;
  }


  final recordsByKey = <String, OfferImportRecord>{};
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
    for (final raw in (source['prospects'] as List<dynamic>? ?? const [])) {
      if (raw is! Map<String, dynamic>) continue;
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
      final issueValidFrom = DateTime.tryParse(
        _stringValue(raw['offerStartDate']) ??
            _stringValue(raw['startDate']) ??
            '',
      );
      final issueValidUntil = DateTime.tryParse(
        _stringValue(raw['offerEndDate']) ??
            _stringValue(raw['endDate']) ??
            '',
      );
      final rawBranchId = _optionalNonEmptyString(raw['branchId']);
      final rawLocation = _optionalNonEmptyString(raw['location']);
      final rawAddress = _optionalNonEmptyString(raw['address']);
      final inheritsSourceContext = rawBranchId == null ||
          (sourceMetadata.branchId != null &&
              rawBranchId == sourceMetadata.branchId);
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
    final category = _firstSourceLabel(
      value,
      const [
        'category',
        'categoryName',
        'category_name',
        'productCategory',
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
      ],
    );
    final originalPrice = _priceValue(originalPriceValue);
    final hasMalformedOriginalPrice = originalPriceValue != null &&
        (originalPrice == null ||
            !originalPrice.isFinite ||
            originalPrice <= 0);
    if (hasMalformedOriginalPrice) continue;
    final regionalOnlyValue = value['regionalOnly'];
    final parsedRegionalOnly = _boolValue(regionalOnlyValue);
    final explicitSourceAdapter = _optionalNonEmptyString(
      value['sourceAdapter'],
    );
    final brochurePage = _intValue(value['brochurePage']);
    final explicitBranchId = _optionalNonEmptyString(value['branchId']);
    final isKaufdaWithoutBranch =
        explicitSourceAdapter?.trim().toLowerCase() == 'kaufda' &&
        explicitBranchId == null;
    // A false/changed-format regional flag cannot promote a publisher-level
    // KaufDA hit to a branch price. The branch assertion must be present on
    // the record itself; source-level branch metadata is only a UI fallback.
    final regionalOnly = isKaufdaWithoutBranch
        ? true
        : (parsedRegionalOnly ?? (regionalOnlyValue != null));
    final sourceFallback = sourceMetadataForOffer(
      storeName,
      explicitBranchId,
    );
    final recordBranchId = regionalOnly
        ? explicitBranchId
        : (explicitBranchId ?? sourceFallback?.branchId);
    final record = OfferImportRecord(
        sourceId: sourceId,
        productLabel: productLabel,
        storeName: storeName,
        ean: ean,
        originalPrice: originalPrice,
        offerPrice: offerPrice,
        validFrom: validFrom,
        validUntil: validUntil,
        source: _stringValue(value['source']) ?? 'retailerWebsite',
        proofRef: _stringValue(value['proofRef']),
        imageUrl: _firstHttpUrl([
              value['imageUrl'],
              value['imageURL'],
              value['image_url'],
              value['image'],
              value['productImage'],
              value['product_image'],
              value['bild'],
              value['bild_app'],
              value['bild_web130'],
              value['bild_web90'],
            ]) ??
            _prospectPageImageForOffer(
              pageImagesByStoreAndNumber,
              storeName: storeName,
              branchId: recordBranchId,
              pageNumber: brochurePage,
              validFrom: validFrom,
              validUntil: validUntil,
            ),
        category: category,
        packageSize: _firstSourceLabel(
          value,
          const ['packageSize', 'package', 'packaging', 'quantityLabel'],
        ),
        priceByBaseUnit: _firstSourceLabel(
          value,
          const ['priceByBaseUnit', 'unitPrice', 'baseUnitPrice'],
        ),
        sourceAdapter:
            explicitSourceAdapter ?? sourceFallback?.sourceAdapter,
        // An unknown explicit regional flag is treated conservatively. It
        // remains visible as diagnostic evidence but cannot become routeable.
        regionalOnly: regionalOnly,
        brochureId: _stringValue(value['brochureId']),
        brochurePage: brochurePage,
        publisherId: _stringValue(value['publisherId']),
        capturedAt: capturedAt,
        branchId: recordBranchId,
        location: regionalOnly
            ? _optionalNonEmptyString(value['location'])
            : (_optionalNonEmptyString(value['location']) ??
                sourceFallback?.location),
        address: regionalOnly
            ? _optionalNonEmptyString(value['address'])
            : (_optionalNonEmptyString(value['address']) ??
                sourceFallback?.address),
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

String _prospectPageImageKey(String storeName, int pageNumber) =>
    '${storeName.trim().toLowerCase()}\\u001f$pageNumber';

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
  final normalizedBranchId = branchId?.trim();
  if (normalizedBranchId == null || normalizedBranchId.isEmpty) return null;
  for (final candidate in candidates) {
    if (candidate.branchId?.trim() != normalizedBranchId) continue;
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

String? _firstHttpUrl(
  Iterable<Object?> values, {
  int depth = 0,
}) {
  if (depth > 2) return null;
  for (final value in values) {
    final url = _httpUrlValue(value);
    if (url != null) return url;
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
          value['original'],
          value['large'],
        ],
        depth: depth + 1,
      );
      if (nested != null) return nested;
    }
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

