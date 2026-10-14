import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/services/prospect_feed_cache.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

class _MemoryProspectFeedCache implements ProspectFeedCache {
  String? raw;
  var saveCount = 0;

  @override
  Future<String?> load() async => raw;

  @override
  Future<void> save(String value) async {
    raw = value;
    saveCount++;
  }
}

class _FakeClient extends http.BaseClient {
  _FakeClient({this.body, this.statusCode = 200, this.error});

  final String? body;
  final int statusCode;
  final Object? error;
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

  test('ein paralleler Read wartet auf einen Prospekt-Cache-Write', () async {
    final cache = SharedPreferencesProspectFeedCache();
    final reader = SharedPreferencesProspectFeedCache();
    final raw = _feed(validUntil: '2026-10-03');

    final writing = cache.save(raw);
    final reading = reader.load();

    await writing;
    expect(await reading, raw);
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
}

