import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/services/prospect_feed_cache.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

class _MemoryProspectFeedCache
    implements ProspectFeedCache, ProspectFeedCaptureMetadataCache {
  String? raw;
  DateTime? capturedAt;
  var saveCount = 0;

  @override
  Future<String?> load() async => raw;

  @override
  Future<void> save(String value) async {
    raw = value;
    saveCount++;
  }

  @override
  Future<DateTime?> loadCapturedAt(String value) async =>
      raw == value ? capturedAt : null;

  @override
  Future<void> saveCapturedAt(String value, DateTime timestamp) async {
    if (raw == value) capturedAt = timestamp;
  }
}

class _FakeClient extends http.BaseClient {
  _FakeClient({
    this.body,
    this.statusCode = 200,
    this.error,
    this.headers = const <String, String>{},
  });

  final String? body;
  final int statusCode;
  final Object? error;
  final Map<String, String> headers;
  http.BaseRequest? lastRequest;
  var requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    lastRequest = request;
    if (error != null) throw error!;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body ?? '')),
      statusCode,
      headers: headers,
      request: request,
    );
  }
}

String _feed({
  required String validUntil,
  String generatedAt = '2026-09-30T04:15:00Z',
}) =>
    '''
{
  "generatedAt": "$generatedAt",
  "sources": [{"storeName": "Lidl", "status": "ok"}],
  "offers": [{
    "sourceId": "cache-1",
    "productLabel": "Milch 1,5 %",
    "storeName": "Lidl",
    "offerPrice": 0.99,
    "validFrom": "2026-09-29",
    "validUntil": "$validUntil",
    "source": "retailerWebsite",
    "proofRef": "https://example.test/cache-1"
  }]
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('the bundled public prospect asset is valid JSON', () async {
    final raw = await rootBundle.loadString(ProspectFeedService.bundledFeedAsset);
    final result = parseProspectFeed(raw);

    expect(result.generatedAt, isNotNull);
    expect(result.records, isNotEmpty);
    final netto = result.prospects.where((issue) => issue.storeName == 'Netto');
    expect(netto, isNotEmpty);
    expect(netto.first.pages, isNotEmpty);
    expect(netto.first.pages.first.number, 1);
    final kaufland = result.prospects.where(
      (issue) => issue.storeName == 'Kaufland',
    );
    expect(kaufland, isNotEmpty);
    expect(kaufland.first.pages, isNotEmpty);
    expect(kaufland.first.pages.first.number, 1);
    final aldi = result.prospects.where(
      (issue) => issue.storeName == 'ALDI Süd',
    );
    expect(aldi, isNotEmpty);
    expect(aldi.first.pages, isNotEmpty);
    expect(aldi.first.pages.first.number, 1);
    final penny = result.prospects.where(
      (issue) => issue.storeName == 'PENNY',
    );
    expect(penny, isNotEmpty);
    expect(penny.first.pages, isNotEmpty);
    expect(penny.first.pages.first.number, 1);
    final edeka = result.prospects.where(
      (issue) => issue.storeName == 'EDEKA',
    );
    expect(edeka, isNotEmpty);
    expect(edeka.first.pages, isNotEmpty);
    expect(edeka.first.pages.first.number, 1);
  });

  test('non-food public feed records are excluded at the app boundary', () {
    final result = parseProspectFeed(
      _feed(validUntil: '2026-10-03').replaceFirst(
        'Milch 1,5 %',
        'ARIEL Colorwaschmittel',
      ),
    );

    expect(result.records, isEmpty);
    expect(isFoodProspectLabel('Pflanzenöl 1 l'), isTrue);
    expect(isFoodProspectLabel('HOME CREATION LED-Kerzen'), isFalse);
    expect(isFoodProspectLabel('DRESDNER ESSENZ Badesalz'), isFalse);
    expect(isFoodProspectLabel('Bepflanztes Holzgefäß'), isFalse);
    for (final label in [
      'CROFTON Halloween Tasse, Fledermaus',
      'MELITTA Filterkaffeemaschine Easy Therm',
      'Deko-Figur Halloween',
      'JACK & JONES Herren-Hoodie',
      'KUSCHELWEICH Weichspüler 1 l',
      'K-CLASSIC Ultra-Klumpstreu 6 l',
      'ALPINA Decken- und Wandweiß 10 l je 10-l-Eimer',
    ]) {
      expect(isFoodProspectLabel(label), isFalse, reason: label);
    }
    expect(
      isFoodProspectLabel('WINTERTRAUM Tassenhänger Knuspermännchen 170 g'),
      isTrue,
    );
    expect(
      isFoodProspectRecord(
        label: 'Gourmet Gold 24 x 85 g',
        category: '09_Drogerie__Tiernahrung',
      ),
      isFalse,
    );
  });

  test('keeps published page totals and missing-page diagnostics', () {
    final result = parseProspectFeed('''
{
  "generatedAt": "2026-10-14T04:15:00Z",
  "sources": [{
    "storeName": "EDEKA",
    "status": "ok",
    "recordCount": 1,
    "prospects": [{
      "title": "EDEKA Prospekt",
      "pageCount": 3,
      "loadedPageCount": 2,
      "missingPageNumbers": [2],
      "pageStatus": "partial",
      "pageCountKnown": true,
      "uncertainProductCount": 1,
      "pageSamples": [
        {"number": 1, "image": "https://example.test/1.jpg"},
        {"number": 3, "image": "https://example.test/3.jpg"}
      ]
    }]
  }],
  "offers": []
}
''');

    final issue = result.prospects.singleWhere((item) => item.storeName == 'EDEKA');
    expect(issue.availablePageCount, 3);
    expect(issue.loadedPageCount, 2);
    expect(issue.missingPageNumbers, [2]);
    expect(issue.pageStatus, 'partial');
    expect(issue.uncertainProductCount, 1);
  });

  test('does not present an unknown cover total as complete pagination', () {
    final result = parseProspectFeed('''
{
  "sources": [{
    "storeName": "PENNY",
    "status": "ok",
    "prospects": [{
      "title": "PENNY Prospekt",
      "pageCount": 1,
      "loadedPageCount": 1,
      "pageStatus": "cover_only",
      "pageCountKnown": false,
      "pageSamples": [
        {"number": 1, "image": "https://example.test/cover.jpg"}
      ]
    }]
  }],
  "offers": []
}
''');

    final issue = result.prospects.singleWhere(
      (item) => item.storeName == 'PENNY',
    );
    expect(issue.pageCountKnown, isFalse);
    expect(issue.availablePageCount, isNull);
    expect(issue.loadedPageCount, 1);
  });

  test('preserves only valid source EAN evidence', () {
    final parsed = parseProspectFeed(
      _feed(validUntil: '2026-10-03').replaceFirst(
        '"offerPrice": 0.99,',
        '"offerPrice": 0.99,\n    "gtin": "04012345678905",',
      ),
    );
    expect(parsed.records.single.ean, '04012345678905');

    final rejected = parseProspectFeed(
      _feed(validUntil: '2026-10-03').replaceFirst(
        '"offerPrice": 0.99,',
        '"offerPrice": 0.99,\n    "gtin": "not-an-ean",',
      ),
    );
    expect(rejected.records, isEmpty);
  });

  test('successful live feed is written to the public cache', () async {
    final cache = _MemoryProspectFeedCache();
    final client = _FakeClient(body: _feed(validUntil: '2026-10-03'));
    final service = ProspectFeedService(
      client: client,
      cache: cache,
      bundledLoader: () async => throw StateError('asset unavailable'),
    );

    final result = await service.load();

    expect(result.fromCache, isFalse);
    expect(result.records, hasLength(1));
    expect(cache.raw, isNotNull);
    expect(cache.saveCount, 1);
    expect(
      client.lastRequest?.headers.entries.any(
        (entry) =>
            entry.key.toLowerCase() == 'user-agent' &&
            entry.value.contains('SparzamApp'),
      ),
      isTrue,
    );
  });

  test('uses Last-Modified when a feed has no generatedAt', () async {
    final body = _feed(validUntil: '2026-10-18').replaceFirst(
      '  "generatedAt": "2026-09-30T04:15:00Z",\n',
      '',
    );
    final service = ProspectFeedService(
      client: _FakeClient(
        body: body,
        headers: const {
          'last-modified': 'Sat, 17 Oct 2026 04:15:00 GMT',
        },
      ),
      cache: _MemoryProspectFeedCache(),
      bundledLoader: () async => throw StateError('asset unavailable'),
    );

    final result = await service.load();

    expect(result.generatedAt, isNull);
    expect(result.capturedAt, DateTime.utc(2026, 10, 17, 4, 15));
    expect(result.records, hasLength(1));
  });

  test('uses Date when Last-Modified is absent', () async {
    final body = _feed(validUntil: '2026-10-18').replaceFirst(
      '  "generatedAt": "2026-09-30T04:15:00Z",\n',
      '',
    );
    final service = ProspectFeedService(
      client: _FakeClient(
        body: body,
        headers: const {
          'date': 'Sat, 17 Oct 2026 04:15:00 GMT',
        },
      ),
      cache: _MemoryProspectFeedCache(),
      bundledLoader: () async => throw StateError('asset unavailable'),
    );

    final result = await service.load();

    expect(result.generatedAt, isNull);
    expect(result.capturedAt, DateTime.utc(2026, 10, 17, 4, 15));
  });

  test('keeps response capture metadata with the cached feed offline', () async {
    final body = _feed(validUntil: '2026-10-18').replaceFirst(
      '  "generatedAt": "2026-09-30T04:15:00Z",\n',
      '',
    );
    final cache = _MemoryProspectFeedCache();
    final online = ProspectFeedService(
      client: _FakeClient(
        body: body,
        headers: const {
          'last-modified': 'Sat, 17 Oct 2026 04:15:00 GMT',
        },
      ),
      cache: cache,
      bundledLoader: () async => throw StateError('asset unavailable'),
    );

    final live = await online.load();
    expect(live.capturedAt, DateTime.utc(2026, 10, 17, 4, 15));

    final offline = ProspectFeedService(
      client: _FakeClient(error: http.ClientException('offline')),
      cache: cache,
      bundledLoader: () async => throw StateError('asset unavailable'),
      networkEnabled: false,
    );

    final cached = await offline.load();
    expect(cached.fromCache, isTrue);
    expect(cached.capturedAt, DateTime.utc(2026, 10, 17, 4, 15));
  });

  test('ein paralleler Read wartet auf einen Prospekt-Cache-Write', () async {
    final cache = SharedPreferencesProspectFeedCache();
    final reader = SharedPreferencesProspectFeedCache();
    final raw = _feed(validUntil: '2026-10-03');

    final writing = cache.save(raw);
    final reading = reader.load();

    await writing;
    expect(await reading, raw);
  });

  test('verwirft übergroße Prospektfeeds statt den lokalen Speicher wachsen zu lassen', () async {
    final cache = SharedPreferencesProspectFeedCache();
    final oversized = 'x' * (SharedPreferencesProspectFeedCache.maxRawBytes + 1);

    await expectLater(cache.save(oversized), throwsA(isA<StateError>()));
    expect(await cache.load(), isNull);
  });

  test('parallele Feed-Ladevorgänge teilen eine laufende Anfrage', () async {
    final client = _FakeClient(body: _feed(validUntil: '2026-10-03'));
    final service = ProspectFeedService(
      client: client,
      cache: _MemoryProspectFeedCache(),
    );

    final first = service.load();
    final second = service.load();

    expect(identical(first, second), isTrue);
    await Future.wait([first, second]);
    expect(client.requestCount, 1);
    service.close();
  });

  test('ein fehlgeschlagener Feed-Load blockiert keinen späteren Retry',
      () async {
    final client = _FakeClient(error: http.ClientException('offline'));
    final service = ProspectFeedService(
      client: client,
      cache: _MemoryProspectFeedCache(),
      bundledLoader: () async => throw StateError('asset unavailable'),
    );

    await expectLater(service.load(), throwsA(isA<http.ClientException>()));
    await expectLater(service.load(), throwsA(isA<http.ClientException>()));

    expect(client.requestCount, 2);
    service.close();
  });

  test('prefers a newer bundled feed over an old cached feed', () async {
    final cache = _MemoryProspectFeedCache()
      ..raw = _feed(
        validUntil: '2026-10-10',
        generatedAt: '2026-10-10T04:15:00Z',
      );
    final service = ProspectFeedService(
      client: _FakeClient(error: http.ClientException('offline')),
      cache: cache,
      bundledLoader: () async => _feed(
        validUntil: '2026-10-17',
        generatedAt: '2026-10-13T04:15:00Z',
      ),
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(result.generatedAt, DateTime.parse('2026-10-13T04:15:00Z'));
    expect(result.records.single.validUntil, DateTime(2026, 10, 17));
  });

  test('does not let an older successful network response hide a newer local feed',
      () async {
    final service = ProspectFeedService(
      client: _FakeClient(
        body: _feed(
          validUntil: '2026-10-10',
          generatedAt: '2026-10-10T04:15:00Z',
        ),
      ),
      cache: _MemoryProspectFeedCache(),
      bundledLoader: () async => _feed(
        validUntil: '2026-10-17',
        generatedAt: '2026-10-13T04:15:00Z',
      ),
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(result.generatedAt, DateTime.parse('2026-10-13T04:15:00Z'));
    expect(result.records.single.validUntil, DateTime(2026, 10, 17));
  });

  test('a valid cached feed is used when the live request fails', () async {
    final cache = _MemoryProspectFeedCache()
      ..raw = _feed(validUntil: '2026-10-03');
    final service = ProspectFeedService(
      client: _FakeClient(error: http.ClientException('offline')),
      cache: cache,
      bundledLoader: () async => throw StateError('asset unavailable'),
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(result.records.single.sourceId, 'cache-1');
  });

  test('disabled network uses local cache without a live request', () async {
    final cache = _MemoryProspectFeedCache()
      ..raw = _feed(validUntil: '2026-10-03');
    final service = ProspectFeedService(
      client: _FakeClient(body: '{"should":"not be requested"}'),
      cache: cache,
      bundledLoader: () async => throw StateError('asset unavailable'),
      networkEnabled: false,
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(result.records.single.sourceId, 'cache-1');
  });

  test('the bundled public feed is used when cache and network are unavailable', () async {
    final service = ProspectFeedService(
      client: _FakeClient(error: http.ClientException('offline')),
      cache: _MemoryProspectFeedCache(),
      bundledLoader: () async => _feed(validUntil: '2026-10-03'),
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(result.records.single.sourceId, 'cache-1');
  });

  test('expired bundled offers remain excluded from current records', () async {
    final service = ProspectFeedService(
      client: _FakeClient(statusCode: 503, body: 'unavailable'),
      cache: _MemoryProspectFeedCache(),
      bundledLoader: () async => _feed(validUntil: '2026-09-29'),
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(
      currentProspectRecords(result.records, now: DateTime(2026, 9, 30, 12)),
      isEmpty,
    );
  });

  test('expired cached offers are never current offers', () async {
    final cache = _MemoryProspectFeedCache()
      ..raw = _feed(validUntil: '2026-09-29');
    final service = ProspectFeedService(
      client: _FakeClient(statusCode: 503, body: 'unavailable'),
      cache: cache,
      bundledLoader: () async => throw StateError('asset unavailable'),
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(
      currentProspectRecords(result.records, now: DateTime(2026, 9, 30, 12)),
      isEmpty,
    );
  });

  test('malformed per-record capture time is rejected', () {
    final result = parseProspectFeed(
      _feed(validUntil: '2026-10-03').replaceFirst(
        '"proofRef": "https://example.test/cache-1"',
        '"proofRef": "https://example.test/cache-1",\n'
        '    "capturedAt": "not-a-date"',
      ),
    );

    expect(result.records, isEmpty);
  });

  test('malformed cache does not hide the live request error', () async {
    final cache = _MemoryProspectFeedCache()..raw = '{not-json';
    final service = ProspectFeedService(
      client: _FakeClient(statusCode: 503, body: 'unavailable'),
      cache: cache,
      bundledLoader: () async => throw StateError('asset unavailable'),
    );

    expect(service.load, throwsA(isA<StateError>()));
  });

  test('preserves current rows from an older local source when the newer source is empty', () {
    final fallback = parseProspectFeed(
      _feed(
        validUntil: '2026-10-21',
        generatedAt: '2026-10-16T04:15:00Z',
      ),
    );
    final incoming = parseProspectFeed('''
{
  "generatedAt": "2026-10-17T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "recordCount": 0,
    "prospects": [{
      "title": "Lidl Wochenprospekt",
      "thumbnailUrl": "https://example.test/lidl-new-cover.jpg",
      "validFrom": "2026-10-15",
      "validUntil": "2026-10-21"
    }]
  }],
  "offers": []
}
''');

    final guarded = preserveCurrentProspectRowsForEmptySources(
      incoming: incoming,
      fallback: fallback,
      now: DateTime(2026, 10, 17, 12),
    );

    expect(guarded.records, hasLength(1));
    expect(guarded.records.single.sourceId, 'cache-1');
    expect(guarded.records.single.validUntil, DateTime(2026, 10, 21));
    final issue = guarded.prospects.firstWhere(
      (entry) => entry.storeName == 'Lidl',
    );
    expect(issue.sourceStatus, 'current_fallback');
    expect(issue.thumbnailUrl, 'https://example.test/lidl-new-cover.jpg');
    expect(issue.recordCount, 1);
  });

  test('replaces a stale duplicate source row with the current fallback row', () {
    final fallback = parseProspectFeed(
      _feed(
        validUntil: '2026-10-21',
        generatedAt: '2026-10-16T04:15:00Z',
      ),
    );
    final incoming = parseProspectFeed('''
{
  "generatedAt": "2026-10-17T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "recordCount": 1
  }],
  "offers": [{
    "sourceId": "cache-1",
    "productLabel": "Milch 1,5 %",
    "storeName": "Lidl",
    "offerPrice": 1.19,
    "validFrom": "2026-10-15",
    "validUntil": "2026-10-16",
    "source": "retailerWebsite",
    "proofRef": "https://example.test/cache-1-stale"
  }]
}
''');

    final guarded = preserveCurrentProspectRowsForEmptySources(
      incoming: incoming,
      fallback: fallback,
      now: DateTime(2026, 10, 17, 12),
    );
    final current = currentProspectRecords(
      guarded.records,
      now: DateTime(2026, 10, 17, 12),
    );

    expect(current, hasLength(1));
    expect(current.single.sourceId, 'cache-1');
    expect(current.single.offerPrice, 0.99);
    expect(
      guarded.prospects
          .firstWhere((entry) => entry.storeName == 'Lidl')
          .sourceStatus,
      'current_fallback',
    );
  });

  test('does not revive expired or non-food rows from the fallback source', () {
    final incoming = parseProspectFeed('''
{
  "generatedAt": "2026-10-17T04:15:00Z",
  "sources": [{"storeName": "Lidl", "status": "ok", "recordCount": 0}],
  "offers": []
}
''');
    final expired = parseProspectFeed(
      _feed(
        validUntil: '2026-10-16',
        generatedAt: '2026-10-16T04:15:00Z',
      ),
    );
    final nonFood = parseProspectFeed(
      _feed(
        validUntil: '2026-10-21',
        generatedAt: '2026-10-16T04:15:00Z',
      ).replaceFirst('Milch 1,5 %', 'HOME CREATION LED-Kerzen'),
    );

    final expiredResult = preserveCurrentProspectRowsForEmptySources(
      incoming: incoming,
      fallback: expired,
      now: DateTime(2026, 10, 17, 12),
    );
    final nonFoodResult = preserveCurrentProspectRowsForEmptySources(
      incoming: incoming,
      fallback: nonFood,
      now: DateTime(2026, 10, 17, 12),
    );

    expect(expiredResult.records, isEmpty);
    expect(nonFoodResult.records, isEmpty);
    expect(
      expiredResult.prospects
          .firstWhere((entry) => entry.storeName == 'Lidl')
          .sourceStatus,
      'ok',
    );
    expect(
      nonFoodResult.prospects
          .firstWhere((entry) => entry.storeName == 'Lidl')
          .sourceStatus,
      'ok',
    );
  });

  test('keeps exact branch boundaries during empty-source fallback', () {
    final fallback = parseProspectFeed('''
{
  "generatedAt": "2026-10-16T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "branchId": "lidl-zellingen"
  }],
  "offers": [{
    "sourceId": "branch-old",
    "productLabel": "Milch 1,5 %",
    "storeName": "Lidl",
    "offerPrice": 0.99,
    "validFrom": "2026-10-15",
    "validUntil": "2026-10-21",
    "source": "retailerWebsite",
    "branchId": "lidl-zellingen",
    "proofRef": "https://example.test/branch-old"
  }]
}
''');
    final incoming = parseProspectFeed('''
{
  "generatedAt": "2026-10-17T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "branchId": "lidl-wuerzburg",
    "recordCount": 0
  }],
  "offers": []
}
''');

    final guarded = preserveCurrentProspectRowsForEmptySources(
      incoming: incoming,
      fallback: fallback,
      now: DateTime(2026, 10, 17, 12),
    );

    expect(guarded.records, isEmpty);
    expect(
      guarded.prospects
          .firstWhere((entry) => entry.storeName == 'Lidl')
          .sourceStatus,
      'ok',
    );
  });


  test('restores validated fallback prospect pages for an empty newer source', () {
    final fallback = parseProspectFeed('''
{
  "generatedAt": "2026-10-16T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "branchId": "lidl-zellingen",
    "prospects": [{
      "title": "Lidl Wochenprospekt 15",
      "url": "https://example.test/lidl-old",
      "thumbnailUrl": "https://example.test/lidl-old-cover.jpg",
      "validFrom": "2026-10-15",
      "validUntil": "2026-10-21",
      "availablePageCount": 1,
      "loadedPageCount": 1,
      "pageStatus": "complete",
      "pageCountKnown": true,
      "pageSamples": [{
        "number": 1,
        "image": "https://example.test/lidl-old-page.jpg"
      }]
    }]
  }],
  "offers": [{
    "sourceId": "fallback-page-row",
    "productLabel": "Milch 1 l",
    "storeName": "Lidl",
    "offerPrice": 0.99,
    "validFrom": "2026-10-15",
    "validUntil": "2026-10-21",
    "source": "retailerWebsite",
    "branchId": "lidl-zellingen",
    "proofRef": "https://example.test/lidl-old?page=1"
  }]
}
''');
    final incoming = parseProspectFeed('''
{
  "generatedAt": "2026-10-17T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "branchId": "lidl-zellingen",
    "recordCount": 0,
    "prospects": [{
      "title": "Lidl Wochenprospekt 17",
      "validFrom": "2026-10-17",
      "validUntil": "2026-10-22",
      "availablePageCount": 8,
      "loadedPageCount": 0,
      "pageCountKnown": true
    }]
  }],
  "offers": []
}
''');

    final guarded = preserveCurrentProspectRowsForEmptySources(
      incoming: incoming,
      fallback: fallback,
      now: DateTime(2026, 10, 17, 12),
    );
    final issue = guarded.prospects.singleWhere((item) => item.storeName == 'Lidl');

    expect(guarded.records.single.sourceId, 'fallback-page-row');
    expect(issue.sourceStatus, 'current_fallback');
    expect(issue.title, 'Lidl Wochenprospekt 17');
    expect(issue.url, 'https://example.test/lidl-old');
    expect(issue.thumbnailUrl, 'https://example.test/lidl-old-cover.jpg');
    expect(issue.pages.single.imageUrl, 'https://example.test/lidl-old-page.jpg');
    expect(issue.availablePageCount, 8);
    expect(issue.loadedPageCount, 1);
    expect(issue.pageStatus, 'complete');
    expect(issue.pageCountKnown, isTrue);
    expect(issue.validFrom, DateTime(2026, 10, 17));
    expect(issue.validUntil, DateTime(2026, 10, 22));
  });

  test('keeps newer prospect pages when row fallback fills an empty source', () {
    final fallback = parseProspectFeed(
      _feed(
        validUntil: '2026-10-21',
        generatedAt: '2026-10-16T04:15:00Z',
      ).replaceFirst(
        '"sources": [{"storeName": "Lidl", "status": "ok"}]',
        '"sources": [{"storeName": "Lidl", "status": "ok", "branchId": "lidl-zellingen", "prospects": [{"pageSamples": [{"number": 1, "image": "https://example.test/old-page.jpg"}]}]}]',
      ).replaceFirst(
        '"storeName": "Lidl",\n    "offerPrice"',
        '"storeName": "Lidl",\n    "branchId": "lidl-zellingen",\n    "offerPrice"',
      ),
    );
    final incoming = parseProspectFeed('''
{
  "generatedAt": "2026-10-17T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "branchId": "lidl-zellingen",
    "recordCount": 0,
    "prospects": [{
      "pageSamples": [{
        "number": 1,
        "image": "https://example.test/new-page.jpg"
      }]
    }]
  }],
  "offers": []
}
''');

    final guarded = preserveCurrentProspectRowsForEmptySources(
      incoming: incoming,
      fallback: fallback,
      now: DateTime(2026, 10, 17, 12),
    );

    final issue = guarded.prospects.singleWhere((item) => item.storeName == 'Lidl');
    expect(issue.sourceStatus, 'current_fallback');
    expect(issue.pages.single.imageUrl, 'https://example.test/new-page.jpg');
  });


  test('keeps a stale local cover without reviving expired offer rows', () {
    final fallback = parseProspectFeed('''
{
  "generatedAt": "2026-10-17T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "branchId": "lidl-zellingen",
    "prospects": [{
      "title": "Lidl Wochenprospekt 12",
      "validFrom": "2026-10-12",
      "validUntil": "2026-10-17",
      "pageSamples": [{
        "number": 1,
        "image": "https://example.test/lidl-stale-page.jpg"
      }]
    }]
  }],
  "offers": [{
    "sourceId": "expired-page-row",
    "productLabel": "Milch 1 l",
    "storeName": "Lidl",
    "offerPrice": 0.99,
    "validFrom": "2026-10-12",
    "validUntil": "2026-10-17",
    "source": "retailerWebsite",
    "branchId": "lidl-zellingen",
    "proofRef": "https://example.test/lidl-stale?page=1"
  }]
}
''');
    final incoming = parseProspectFeed('''
{
  "generatedAt": "2026-10-18T04:15:00Z",
  "sources": [{
    "storeName": "Lidl",
    "status": "ok",
    "branchId": "lidl-zellingen",
    "recordCount": 0,
    "prospects": [{
      "title": "Lidl Wochenprospekt 18"
    }]
  }],
  "offers": []
}
''');

    final guarded = preserveCurrentProspectRowsForEmptySources(
      incoming: incoming,
      fallback: fallback,
      now: DateTime(2026, 10, 18, 12),
    );
    final issue = guarded.prospects.singleWhere((item) => item.storeName == 'Lidl');

    expect(guarded.records, isEmpty);
    expect(issue.sourceStatus, 'stale_fallback');
    expect(issue.pages.single.imageUrl, 'https://example.test/lidl-stale-page.jpg');
    expect(issue.validUntil, DateTime(2026, 10, 17));
  });

}

