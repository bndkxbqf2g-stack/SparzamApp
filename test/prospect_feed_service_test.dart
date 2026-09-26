import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  test('feed parser keeps verified regular price optional', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-09-25T04:15:00Z",
  "sources": [
    {"storeName": "ALDI Süd", "status": "ok"},
    {"storeName": "Lidl", "status": "metadata_only"}
  ],
  "offers": [
    {
      "sourceId": "a1",
      "productLabel": "Schmand",
      "storeName": "ALDI Süd",
      "offerPrice": 0.69,
      "originalPrice": 0.89,
      "validFrom": "2026-09-21",
      "validUntil": "2026-09-26",
      "source": "retailerWebsite",
      "proofRef": "https://example.test/a1"
    },
    {
      "sourceId": "e1",
      "productLabel": "Vollmilch 3,5 %",
      "storeName": "EDEKA",
      "offerPrice": 0.99,
      "validFrom": "2026-09-21",
      "validUntil": "2026-09-26",
      "source": "retailerWebsite",
      "proofRef": "https://example.test/e1"
    }
  ]
}
''');

    expect(result.records, hasLength(2));
    expect(result.refreshedStores, ['ALDI Süd']);
    expect(result.records.first.originalPrice, 0.89);
    expect(result.records.last.originalPrice, isNull);
  });

  test('keeps all seven configured retailers visible when a source has no data', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-09-26T04:15:00Z",
  "sources": [
    {"storeName": "Lidl", "status": "ok", "url": "https://lidl.example"},
    {"storeName": "Netto", "status": "error"},
    {"storeName": "REWE", "status": "error"}
  ],
  "offers": []
}
''');

    expect(
      result.prospects.map((item) => item.storeName).toSet(),
      containsAll(configuredProspectStores),
    );
    expect(
      result.prospects.map((item) => item.storeName).toSet(),
      hasLength(configuredProspectStores.length),
    );
    expect(
      result.prospects.firstWhere((item) => item.storeName == 'Netto').url,
      officialProspectUrl('Netto'),
    );
    expect(
      result.prospects.firstWhere((item) => item.storeName == 'REWE').url,
      officialProspectUrl('REWE'),
    );
  });
}
