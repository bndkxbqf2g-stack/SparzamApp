import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (error != null) throw error!;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body ?? '')),
      statusCode,
      request: request,
    );
  }
}

String _feed({required String validUntil}) =>
    '''
{
  "generatedAt": "2026-09-30T04:15:00Z",
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
  test('successful live feed is written to the public cache', () async {
    final cache = _MemoryProspectFeedCache();
    final service = ProspectFeedService(
      client: _FakeClient(body: _feed(validUntil: '2026-10-03')),
      cache: cache,
    );

    final result = await service.load();

    expect(result.fromCache, isFalse);
    expect(result.records, hasLength(1));
    expect(cache.raw, isNotNull);
    expect(cache.saveCount, 1);
  });

  test('a valid cached feed is used when the live request fails', () async {
    final cache = _MemoryProspectFeedCache()
      ..raw = _feed(validUntil: '2026-10-03');
    final service = ProspectFeedService(
      client: _FakeClient(error: http.ClientException('offline')),
      cache: cache,
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(result.records.single.sourceId, 'cache-1');
  });

  test('expired cached offers are never current offers', () async {
    final cache = _MemoryProspectFeedCache()
      ..raw = _feed(validUntil: '2026-09-29');
    final service = ProspectFeedService(
      client: _FakeClient(statusCode: 503, body: 'unavailable'),
      cache: cache,
    );

    final result = await service.load();

    expect(result.fromCache, isTrue);
    expect(
      currentProspectRecords(result.records, now: DateTime(2026, 9, 30, 12)),
      isEmpty,
    );
  });

  test('malformed cache does not hide the live request error', () async {
    final cache = _MemoryProspectFeedCache()..raw = '{not-json';
    final service = ProspectFeedService(
      client: _FakeClient(statusCode: 503, body: 'unavailable'),
      cache: cache,
    );

    expect(service.load, throwsA(isA<StateError>()));
  });
}
