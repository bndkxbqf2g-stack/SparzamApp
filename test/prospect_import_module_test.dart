import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparzamapp/services/prospect_import_module.dart';
import 'package:sparzamapp/services/prospect_feed_cache.dart';

class _MemoryProspectFeedCache implements ProspectFeedCache {
  String? value;

  @override
  Future<String?> load() async => value;

  @override
  Future<void> save(String raw) async => value = raw;
}

void main() {
  test(
    'start-address URL enrichment keeps prospect branch provenance',
    () async {
      final client = MockClient(
        (_) async => http.Response('''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [
    {
      "storeName": "ALDI Süd",
      "status": "ok",
      "branchId": "B384",
      "location": "Zellingen",
      "address": "Würzburger Str. 74, 97225 Zellingen, Germany"
    }
  ],
  "offers": []
}
''', 200),
      );

      final result = await ProspectImportModule(
        client: client,
        cache: _MemoryProspectFeedCache(),
      ).execute(startAddress: '97225 Zellingen, Germany');
      final aldi = result.prospects.firstWhere(
        (issue) => issue.storeName == 'ALDI Süd',
      );

      expect(aldi.url, 'https://www.aldi-sued.de/');
      expect(aldi.branchId, 'B384');
      expect(aldi.location, 'Zellingen');
      expect(aldi.address, contains('Würzburger Str. 74'));
    },
  );

  test(
    'start-address enrichment preserves capture-only feed time',
    () async {
      final client = MockClient(
        (_) async => http.Response('''
{
  "capturedAt": "2026-10-01T04:15:00Z",
  "sources": [
    {
      "storeName": "ALDI Süd",
      "status": "ok",
      "branchId": "B384",
      "location": "Zellingen",
      "address": "Würzburger Str. 74, 97225 Zellingen, Germany"
    }
  ],
  "offers": []
}
''', 200),
      );

      final module = ProspectImportModule(
        client: client,
        cache: _MemoryProspectFeedCache(),
      );
      final result = await module.execute(
        startAddress: '97225 Zellingen, Germany',
      );

      expect(result.generatedAt, isNull);
      expect(result.capturedAt, DateTime.utc(2026, 10, 1, 4, 15));
      module.close();
    },
  );

  test('start-address enrichment keeps page coverage diagnostics', () async {
    final client = MockClient(
      (_) async => http.Response('''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [{
    "storeName": "EDEKA",
    "status": "ok",
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
''', 200),
    );

    final result = await ProspectImportModule(
      client: client,
      cache: _MemoryProspectFeedCache(),
    ).execute(startAddress: '97225 Zellingen, Germany');
    final edeka = result.prospects.firstWhere(
      (issue) => issue.storeName == 'EDEKA',
    );

    expect(edeka.availablePageCount, 3);
    expect(edeka.loadedPageCount, 2);
    expect(edeka.missingPageNumbers, [2]);
    expect(edeka.pageStatus, 'partial');
    expect(edeka.uncertainProductCount, 1);
  });

  test(
    'cached feed can render before the first network refresh',
    () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('''
{
  "generatedAt": "2026-10-12T05:00:00Z",
  "sources": [
    {"storeName": "Lidl", "status": "ok"}
  ],
  "offers": []
}
''', 200);
      });
      final cache = _MemoryProspectFeedCache()
        ..value = '''
{
  "generatedAt": "2026-10-12T04:00:00Z",
  "sources": [
    {"storeName": "Lidl", "status": "ok"}
  ],
  "offers": []
}
''';
      final module = ProspectImportModule(client: client, cache: cache);

      final cached = await module.executeCached(
        startAddress: '97225 Zellingen, Germany',
      );

      expect(cached, isNotNull);
      expect(cached!.fromCache, isTrue);
      expect(cached.generatedAt, DateTime.utc(2026, 10, 12, 4));
      expect(requestCount, 0);

      final refreshed = await module.execute(
        startAddress: '97225 Zellingen, Germany',
      );

      expect(refreshed.fromCache, isFalse);
      expect(refreshed.generatedAt, DateTime.utc(2026, 10, 12, 5));
      expect(requestCount, 1);
      module.close();
    },
  );

}
