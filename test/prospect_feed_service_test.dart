import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  test('feed parser keeps verified regular price optional', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-09-25T04:15:00Z",
  "sources": [
    {
      "storeName": "ALDI Süd",
      "status": "ok",
      "branchId": "B384",
      "location": "Zellingen",
      "address": "Würzburger Str. 74, 97225 Zellingen, Germany"
    },
    {"storeName": "Lidl", "status": "metadata_only"}
  ],
  "offers": [
    {
      "sourceId": "a1",
      "productLabel": "Schmand",
      "storeName": "ALDI Süd",
      "offerPrice": 0.69,
      "category": "Milchprodukte",
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
    expect(result.records.first.category, 'Milchprodukte');
    expect(result.records.first.branchId, 'B384');
    expect(result.records.first.location, 'Zellingen');
    expect(result.records.first.address, contains('Würzburger Str. 74'));
    expect(result.records.last.originalPrice, isNull);
    final aldi = result.prospects.firstWhere(
      (item) => item.storeName == 'ALDI Süd',
    );
    expect(aldi.branchId, 'B384');
    expect(aldi.location, 'Zellingen');
    expect(aldi.address, contains('Würzburger Str. 74'));
  });

  test(
    'keeps all six configured retailers visible when a source has no data',
    () {
      final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-09-26T04:15:00Z",
  "sources": [
    {"storeName": "Lidl", "status": "ok", "url": "https://lidl.example"},
    {"storeName": "Netto", "status": "error"}
  ],
  "offers": []
}
''');

      expect(
        result.prospects.map((item) => item.storeName).toSet(),
        containsAll(configuredProspectStores),
      );
      expect(result.prospects, hasLength(configuredProspectStores.length));
      expect(
        result.prospects.firstWhere((item) => item.storeName == 'Netto').url,
        officialProspectUrl('Netto'),
      );
      expect(
        result.prospects
            .firstWhere((item) => item.storeName == 'Netto')
            .sourceStatus,
        'error',
      );
    },
  );

  test('parses Bring brochure pages and leaflet evidence', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-09-29T18:00:00Z",
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "recordCount": 1,
      "prospects": [
        {
          "id": "brn:bring-de:offersbrochure:218970",
          "title": "Lidl",
          "offerStartDate": "2026-09-28",
          "offerEndDate": "2026-10-03",
          "url": "https://deeplink.getbring.com/view/offers/bring-de/brn:bring-de:offersbrochure:218970/0",
          "thumbnailUrl": "https://cdn.example/cover.jpg",
          "pageSamples": [
            {
              "number": 1,
              "image": "https://cdn.example/page1.jpg",
              "zoom": "https://cdn.example/page1.jpg",
              "keyWords": "Milbona Schmand 200 g"
            }
          ]
        }
      ]
    }
  ],
  "offers": [
    {
      "sourceId": "bring-lidl-1",
      "productLabel": "Milbona Schmand 200 g",
      "storeName": "Lidl",
      "offerPrice": 0.69,
      "originalPrice": 0.89,
      "validFrom": "2026-09-28",
      "validUntil": "2026-10-03",
      "source": "leaflet",
      "proofRef": "https://deeplink.getbring.com/view/offers/bring-de/brn:bring-de:offersbrochure:218970/0",
      "imageUrl": "https://cdn.example/schmand.png"
    }
  ]
}
''');

    final lidl = result.prospects.firstWhere(
      (item) => item.storeName == 'Lidl',
    );
    expect(lidl.pages, hasLength(1));
    expect(lidl.pages.single.imageUrl, 'https://cdn.example/page1.jpg');
    expect(lidl.recordCount, 1);
    expect(lidl.validFrom, DateTime(2026, 9, 28));
    expect(lidl.validUntil, DateTime(2026, 10, 3));
    expect(result.records, hasLength(1));
    expect(result.records.single.source, 'leaflet');
    expect(result.records.single.offerPrice, 0.69);
    expect(result.records.single.originalPrice, 0.89);
    expect(result.records.single.imageUrl, 'https://cdn.example/schmand.png');
    expect(result.records.single.proofRef, contains('offersbrochure:218970'));
  });

  test('keeps prospect validity and link when page images are missing', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [
    {
      "storeName": "EDEKA",
      "status": "ok",
      "branchId": "023738",
      "location": "Zellingen",
      "prospects": [
        {
          "title": "EDEKA Wochenangebote",
          "offerStartDate": "2026-09-28",
          "offerEndDate": "2026-10-03",
          "url": "https://example.test/edeka-prospekt"
        }
      ]
    }
  ],
  "offers": []


}
''');

    final edeka = result.prospects.singleWhere(
      (item) => item.storeName == 'EDEKA',
    );
    expect(edeka.pages, isEmpty);
    expect(edeka.validFrom, DateTime(2026, 9, 28));
    expect(edeka.validUntil, DateTime(2026, 10, 3));
    expect(edeka.url, 'https://example.test/edeka-prospekt');
    expect(edeka.branchId, '023738');
    expect(edeka.location, 'Zellingen');
  });

  test('prefers record-level branch context when a feed has multiple locations', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-02T04:15:00Z",
  "sources": [
    {
      "storeName": "EDEKA",
      "status": "ok",
      "branchId": "source-branch",
      "location": "source-city",
      "prospects": [
        {
          "title": "EDEKA Wochenangebote",
          "branchId": "page-branch",
          "location": "page-city",
          "address": "Page street 1",
          "offerStartDate": "2026-09-28",
          "offerEndDate": "2026-10-03"
        }
      ]
    }
  ],
  "offers": [
    {
      "sourceId": "edeka-page-1",
      "productLabel": "Kaffee Crema 500 g",
      "storeName": "EDEKA",
      "offerPrice": 4.99,
      "validUntil": "2026-10-03",
      "source": "leaflet",
      "proofRef": "https://example.test/edeka-page-1",
      "branchId": "offer-branch",
      "location": "offer-city",
      "address": "Offer street 2"
    }
  ]
}
''');

    final issue = result.prospects.singleWhere(
      (item) => item.storeName == 'EDEKA',
    );
    expect(issue.branchId, 'page-branch');
    expect(issue.location, 'page-city');
    expect(issue.address, 'Page street 1');
    expect(result.records.single.branchId, 'offer-branch');
    expect(result.records.single.location, 'offer-city');
    expect(result.records.single.address, 'Offer street 2');
  });

  test('rejects malformed or contradictory offer validity evidence', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [{"storeName": "Lidl", "status": "ok"}],
  "offers": [
    {
      "sourceId": "bad-start",
      "productLabel": "Milch 1,5 %",
      "storeName": "Lidl",
      "offerPrice": 0.99,
      "validFrom": "unbekannt",
      "validUntil": "2026-10-03"
    },
    {
      "sourceId": "reversed",
      "productLabel": "Butter",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "validFrom": "2026-10-04",
      "validUntil": "2026-10-03"
    },
    {
      "sourceId": "bad-original",
      "productLabel": "Kaffee",
      "storeName": "Lidl",
      "offerPrice": 4.99,
      "originalPrice": "unbekannt",
      "validUntil": "2026-10-03"
    },
    {
      "sourceId": "bad-price-type",
      "productLabel": "Tee",
      "storeName": "Lidl",
      "offerPrice": "0.99",
      "validUntil": "2026-10-03"
    },
    {
      "sourceId": "valid",
      "productLabel": "Joghurt",
      "storeName": "Lidl",
      "offerPrice": 0.69,
      "validFrom": "2026-09-28",
      "validUntil": "2026-10-03",
      "originalPrice": 0.89
    }
  ]
}
''');

    expect(result.records, hasLength(1));
    expect(result.records.single.sourceId, 'valid');
    expect(result.records.single.validFrom, DateTime(2026, 9, 28));
    expect(result.records.single.originalPrice, 0.89);
  });

}