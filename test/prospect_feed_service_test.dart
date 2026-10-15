import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';
import 'package:sparzamapp/services/prospect_feed_cache.dart';

class _MemoryProspectFeedCache implements ProspectFeedCache {
  _MemoryProspectFeedCache(this.value);

  final String? value;

  @override
  Future<String?> load() async => value;

  @override
  Future<void> save(String raw) async {}
}

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
      "packageSize": "200 g",
      "priceByBaseUnit": "3,45 €/kg",
      "sourceAdapter": "kaufda",
      "regionalOnly": "false",
      "brochureId": "brochure-1",
      "brochurePage": "4",
      "publisherId": "lidl",
      "originalPrice": 0.89,
      "branchId": "B384",
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
    expect(result.records.first.packageSize, '200 g');
    expect(result.records.first.priceByBaseUnit, '3,45 €/kg');
    expect(result.records.first.sourceAdapter, 'kaufda');
    expect(result.records.first.regionalOnly, isFalse);
    expect(result.records.first.brochureId, 'brochure-1');
    expect(result.records.first.brochurePage, 4);
    expect(result.records.first.publisherId, 'lidl');
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


  test('matches source metadata despite store-name formatting', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-15T04:15:00Z",
  "sources": [
    {
      "storeName": "LIDL",
      "status": "ok",
      "branchId": "lidl-zellingen",
      "location": "Zellingen",
      "address": "Branch street 1"
    }
  ],
  "offers": [
    {
      "sourceId": "formatted-store",
      "productLabel": "Butter 250 g",
      "storeName": " lidl ",
      "offerPrice": 1.99,
      "validUntil": "2026-10-17",
      "source": "retailerWebsite",
      "proofRef": "https://example.test/lidl/butter"
    }
  ]
}
''');

    expect(result.records, hasLength(1));
    expect(result.records.single.branchId, 'lidl-zellingen');
    expect(result.records.single.location, 'Zellingen');
    expect(result.records.single.address, 'Branch street 1');
    expect(result.refreshedStores, ['LIDL']);
    expect(
      result.prospects
          .where((item) => item.storeName.trim().toLowerCase() == 'lidl'),
      hasLength(1),
    );
  });

  test('keeps formatted same-name branches ambiguous without a branch id', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-15T04:15:00Z",
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-zellingen",
      "location": "Zellingen"
    },
    {
      "storeName": " lidl ",
      "status": "ok",
      "branchId": "lidl-wuerzburg",
      "location": "Würzburg"
    }
  ],
  "offers": [
    {
      "sourceId": "ambiguous-formatted-store",
      "productLabel": "Butter 250 g",
      "storeName": "LIDL",
      "offerPrice": 1.99,
      "validUntil": "2026-10-17",
      "source": "retailerWebsite",
      "proofRef": "https://example.test/lidl/butter"
    }
  ]
}
''');

    expect(result.records, hasLength(1));
    expect(result.records.single.branchId, isNull);
    expect(result.records.single.location, isNull);
    expect(result.records.single.address, isNull);
  });

  test('accepts explicit regular-price aliases from feed adapters', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-14T05:57:41Z",
  "sources": [
    {"storeName": "ALDI Süd", "status": "ok", "branchId": "B384"}
  ],
  "offers": [
    {
      "sourceId": "regular-alias-1",
      "productLabel": "H-Milch 1 l",
      "storeName": "ALDI Süd",
      "offerPrice": 0.99,
      "regularPrice": 1.29,
      "validUntil": "2026-10-17",
      "proofRef": "https://example.test/aldi/milch"
    },
    {
      "sourceId": "regular-alias-2",
      "productLabel": "Butter 250 g",
      "storeName": "ALDI Süd",
      "offerPrice": 1.49,
      "normalPrice": 1.99,
      "validUntil": "2026-10-17",
      "proofRef": "https://example.test/aldi/butter"
    }
  ]
}
''');

    expect(result.records, hasLength(2));
    expect(result.records[0].originalPrice, 1.29);
    expect(result.records[1].originalPrice, 1.99);
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

  test('uses the first validated page as a legacy cover fallback', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [
    {
      "storeName": "ALDI Süd",
      "status": "metadata_only",
      "prospects": [
        {
          "title": "ALDI Prospekt",
          "pageSamples": [
            {
              "number": 1,
              "image": "https://cdn.example/aldi-cover.jpg"
            }
          ]
        }
      ]
    }
  ],
  "offers": []
}
''');

    final aldi = result.prospects.firstWhere(
      (item) => item.storeName == 'ALDI Süd',
    );
    expect(aldi.pages, hasLength(1));
    expect(aldi.thumbnailUrl, 'https://cdn.example/aldi-cover.jpg');
  });


  test('preserves declared page count separately from loaded samples', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "prospects": [
        {
          "title": "Lidl Wochenprospekt",
          "pageCount": 73,
          "pageCountKnown": true,
          "loadedPageCount": 2,
          "pageSamples": [
            {"number": 1, "image": "https://example.test/page-1.jpg"},
            {"number": 5, "image": "https://example.test/page-5.jpg"}
          ]
        }
      ]
    }
  ],
  "offers": []
}
''');

    final issue = result.prospects.singleWhere(
      (item) => item.storeName == 'Lidl',
    );
    expect(issue.pages, hasLength(2));
    expect(issue.availablePageCount, 73);
    expect(issue.loadedPageCount, 2);
    expect(issue.pageCountKnown, isTrue);
  });

  test('accepts alternate cover and page image fields', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-zellingen",
      "prospects": [
        {
          "title": "Lidl Wochenprospekt",
          "coverUrl": "https://cdn.example/cover-alt.jpg",
          "pageSamples": [
            {
              "pageNumber": "2",
              "imageUrl": "https://cdn.example/page-2.jpg",
              "zoomUrl": "https://cdn.example/page-2-large.jpg",
              "keywords": "Butter 250 g"
            }
          ]
        }
      ]
    }
  ],
  "offers": []
}
''');

    final issue = result.prospects.firstWhere(
      (item) => item.storeName == 'Lidl',
    );
    expect(issue.thumbnailUrl, 'https://cdn.example/cover-alt.jpg');
    expect(issue.pages, hasLength(1));
    expect(issue.pages.single.number, 2);
    expect(issue.pages.single.imageUrl, 'https://cdn.example/page-2.jpg');
    expect(issue.pages.single.zoomUrl, 'https://cdn.example/page-2-large.jpg');
    expect(issue.pages.single.keyWords, 'Butter 250 g');
  });
  test('normalizes explicit article evidence aliases', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-14T05:57:41Z",
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl_zellingen",
      "location": "Zellingen",
      "prospects": [
        {
          "title": "Lidl Wochenprospekt",
          "pageSamples": [
            {
              "number": 1,
              "image": {"url": "https://cdn.example/lidl-cover.jpg"}
            }
          ]
        }
      ]
    }
  ],
  "offers": [
    {
      "sourceId": "evidence-alias-1",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "streichpreis": 1.99,
      "validFrom": "2026-10-12",
      "validUntil": "2026-10-17",
      "proofRef": "https://example.test/lidl/butter",
      "productImage": {"src": "https://cdn.example/lidl-butter.jpg"},
      "productCategory": {"title": "Milchprodukte"},
      "packaging": "250 g",
      "baseUnitPrice": "5,96 €/kg"
    }
  ]
}
''');

    final record = result.records.single;
    expect(record.originalPrice, 1.99);
    expect(record.imageUrl, 'https://cdn.example/lidl-butter.jpg');
    expect(record.category, 'Milchprodukte');
    expect(record.packageSize, '250 g');
    expect(record.priceByBaseUnit, '5,96 €/kg');
    final issue = result.prospects.singleWhere(
      (item) => item.storeName == 'Lidl',
    );
    expect(issue.pages.single.imageUrl, 'https://cdn.example/lidl-cover.jpg');
  });

  test('uses a validated prospect page as the article image fallback', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-zellingen",
      "prospects": [
        {
          "title": "Lidl Wochenprospekt",
          "offerStartDate": "2026-10-12",
          "offerEndDate": "2026-10-17",
          "pageSamples": [
            {"number": 3, "image": "https://cdn.example/lidl/page-3.jpg"}
          ]
        }
      ]
    }
  ],
  "offers": [
    {
      "sourceId": "lidl-page-3",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "validFrom": "2026-10-12",
      "validUntil": "2026-10-17",
      "brochurePage": 3,
      "branchId": "lidl-zellingen",
      "proofRef": "https://example.test/lidl-page-3"
    }
  ]
}
''');

    expect(result.records.single.imageUrl, 'https://cdn.example/lidl/page-3.jpg');
  });

  test('does not use a page image from another branch', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-zellingen",
      "prospects": [
        {
          "offerStartDate": "2026-10-12",
          "offerEndDate": "2026-10-17",
          "pageSamples": [
            {"number": 3, "image": "https://cdn.example/lidl/page-3.jpg"}
          ]
        }
      ]
    }
  ],
  "offers": [
    {
      "sourceId": "other-branch",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "validFrom": "2026-10-12",
      "validUntil": "2026-10-17",
      "brochurePage": 3,
      "branchId": "lidl-wuerzburg",
      "proofRef": "https://example.test/other-branch"
    }
  ]
}
''');

    expect(result.records.single.imageUrl, isNull);
  });

  test('deduplicates and sorts valid prospect pages', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "prospects": [
        {
          "pageSamples": [
            {"number": 3, "image": "https://cdn.example/page-3.jpg"},
            {"number": 1, "image": "https://cdn.example/page-1.jpg"},
            {"number": 3, "image": "https://cdn.example/page-3-duplicate.jpg"},
            {"number": 0, "image": "https://cdn.example/invalid.jpg"}
          ]
        }
      ]
    }
  ],
  "offers": []
}
''');

    final pages = result.prospects
        .firstWhere((item) => item.storeName == 'Lidl')
        .pages;
    expect(pages.map((page) => page.number), [1, 3]);
    expect(pages.map((page) => page.imageUrl), [
      'https://cdn.example/page-1.jpg',
      'https://cdn.example/page-3.jpg',
    ]);
  });

  test('tolerates string metadata numbers without relaxing price validation', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "recordCount": "2",
      "prospects": [
        {
          "title": "Lidl Wochenprospekt",
          "offerStartDate": "2026-09-28",
          "offerEndDate": "2026-10-03",
          "pageSamples": [
            {"number": "1", "image": "https://example.test/page.jpg"}
          ]
        }
      ]
    }
  ],
  "offers": [
    {
      "sourceId": "string-price",
      "productLabel": "Milch 1 l",
      "storeName": "Lidl",
      "offerPrice": "0.99",
      "validUntil": "2026-10-03",
      "proofRef": "https://example.test/string-price"
    }
  ]
}
''');

    final prospect = result.prospects.singleWhere(
      (item) => item.storeName == 'Lidl',
    );
    expect(prospect.recordCount, 2);
    expect(prospect.pages.single.number, 1);
    expect(result.records, isEmpty);
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

  test('keeps same-name source branches separate in prospect metadata', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-a",
      "location": "Würzburg",
      "address": "Branch A",
      "prospects": [
        {"title": "Lidl A", "offerStartDate": "2026-10-12", "offerEndDate": "2026-10-17"}
      ]
    },
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-b",
      "location": "Zellingen",
      "address": "Branch B",
      "prospects": [
        {"title": "Lidl B", "offerStartDate": "2026-10-12", "offerEndDate": "2026-10-17"}
      ]
    }
  ],
  "offers": []
}
''');

    final issues = result.prospects
        .where((item) => item.storeName == 'Lidl')
        .toList(growable: false);
    expect(issues, hasLength(2));
    expect(issues.map((item) => item.branchId), ['lidl-a', 'lidl-b']);
    expect(issues.map((item) => item.location), ['Würzburg', 'Zellingen']);
    expect(issues.map((item) => item.address), ['Branch A', 'Branch B']);
  });

  test('does not inherit source location for a conflicting record branch', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-a",
      "location": "Würzburg",
      "address": "Branch A",
      "prospects": [
        {
          "title": "Lidl B",
          "branchId": "lidl-b",
          "location": null,
          "address": null
        }
      ]
    }
  ],
  "offers": []
}
''');

    final issue = result.prospects
        .firstWhere((item) => item.title == 'Lidl B');
    expect(issue.branchId, 'lidl-b');
    expect(issue.location, isNull);
    expect(issue.address, isNull);
  });

  test('leaves same-name offers unscoped without an explicit branch', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-a",
      "location": "Würzburg"
    },
    {
      "storeName": "Lidl",
      "status": "ok",
      "branchId": "lidl-b",
      "location": "Zellingen"
    }
  ],
  "offers": [
    {
      "sourceId": "ambiguous",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "originalPrice": 1.99,
      "validFrom": "2026-10-12",
      "validUntil": "2026-10-17",
      "proofRef": "https://example.test/ambiguous"
    },
    {
      "sourceId": "explicit",
      "productLabel": "Milch 1 l",
      "storeName": "Lidl",
      "offerPrice": 0.99,
      "originalPrice": 1.29,
      "validFrom": "2026-10-12",
      "validUntil": "2026-10-17",
      "branchId": "lidl-b",
      "proofRef": "https://example.test/explicit"
    }
  ]
}
''');

    final ambiguous = result.records
        .firstWhere((record) => record.sourceId == 'ambiguous');
    expect(ambiguous.branchId, isNull);
    expect(ambiguous.location, isNull);
    final explicit = result.records
        .firstWhere((record) => record.sourceId == 'explicit');
    expect(explicit.branchId, 'lidl-b');
    expect(explicit.location, 'Zellingen');
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

  test('unknown regional flags stay non-routeable', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [
    {"storeName": "Lidl", "branchId": "lidl_zellingen", "location": "Zellingen", "address": "Am Güßgraben 2"}
  ],
  "offers": [
    {
      "sourceId": "regional-unknown",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "validUntil": "2026-10-03",
      "source": "retailerWebsite",
      "proofRef": "https://www.kaufda.de/Wuerzburg/Angebote/Butter",
      "regionalOnly": "changed-format"
    }
  ]
}
''');

    expect(result.records, hasLength(1));
    expect(result.records.single.regionalOnly, isTrue);
    expect(result.records.single.branchId, isNull);
    expect(result.records.single.location, isNull);
    expect(result.records.single.address, isNull);
  });

  test('legacy KaufDA records without a branch stay regional', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {"storeName": "Lidl", "branchId": "lidl_zellingen", "location": "Zellingen"}
  ],
  "offers": [
    {
      "sourceId": "legacy-kaufda",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.29,
      "validUntil": "2026-10-17",
      "sourceAdapter": "kaufda",
      "proofRef": "https://www.kaufda.de/Wuerzburg/Angebote/Butter"
    }
  ]
}
''');

    expect(result.records.single.regionalOnly, isTrue);
    expect(result.records.single.branchId, isNull);
    expect(result.records.single.location, isNull);
  });

  test('KaufDA cannot become routeable through a false regional flag', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {"storeName": "Lidl", "branchId": "lidl_zellingen", "location": "Zellingen"}
  ],
  "offers": [
    {
      "sourceId": "false-regional-flag",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.29,
      "validUntil": "2026-10-17",
      "source": "retailerWebsite",
      "sourceAdapter": "kaufda",
      "regionalOnly": false,
      "branchId": null,
      "proofRef": "https://www.kaufda.de/Wuerzburg/Angebote/Butter"
    }
  ]
}
''');

    expect(result.records.single.regionalOnly, isTrue);
    expect(result.records.single.branchId, isNull);
    expect(result.records.single.location, isNull);
  });

  test('invalid image references are dropped before the scroll UI', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-01T04:15:00Z",
  "sources": [
    {
      "storeName": "Lidl",
      "status": "ok",
      "prospects": [
        {
          "title": "Lidl Wochenprospekt",
          "thumbnailUrl": "javascript:alert(1)",
          "pageSamples": [
            {
              "number": 1,
              "image": "not-a-url",
              "zoom": "https://example.test/page-large.jpg"
            }
          ]
        }
      ]
    }
  ],
  "offers": [
    {
      "sourceId": "invalid-image",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "validUntil": "2026-10-03",
      "proofRef": "https://example.test/offer",
      "imageUrl": "data:image/png;base64,invalid"
    }
  ]
}
''');

    final issue = result.prospects.firstWhere(
      (item) => item.storeName == 'Lidl',
    );
    expect(issue.thumbnailUrl, isNull);
    expect(issue.pages, isEmpty);
    expect(result.records.single.imageUrl, isNull);
  });

  test('deduplicates identical offer records but keeps changed prices', () {
    final result = parseProspectFeed(r'''
{
  "sources": [
    {"storeName": "Lidl", "status": "ok", "branchId": "lidl-zellingen"}
  ],
  "offers": [
    {
      "sourceId": "duplicate",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "originalPrice": 1.99,
      "packageSize": "250 g",
      "validUntil": "2026-10-17",
      "source": "leaflet",
      "proofRef": "https://example.test/duplicate?page=1"
    },
    {
      "sourceId": "duplicate",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.49,
      "originalPrice": 1.99,
      "packageSize": "250 g",
      "validUntil": "2026-10-17",
      "source": "leaflet",
      "proofRef": "https://example.test/duplicate?page=2"
    },
    {
      "sourceId": "duplicate",
      "productLabel": "Butter 250 g",
      "storeName": "Lidl",
      "offerPrice": 1.39,
      "originalPrice": 1.99,
      "packageSize": "250 g",
      "validUntil": "2026-10-17",
      "source": "leaflet",
      "proofRef": "https://example.test/duplicate?page=3"
    }
  ]
}
''');

    expect(result.records, hasLength(2));
    expect(result.records.map((record) => record.offerPrice), [1.49, 1.39]);
  });
  test('reuses parsed local feed snapshots across cached reads', () async {
    final raw = r'''
{
  "generatedAt": "2026-10-14T05:57:41Z",
  "sources": [
    {"storeName": "Lidl", "status": "ok"}
  ],
  "offers": []
}
''';
    final cache = _MemoryProspectFeedCache(raw);
    final service = ProspectFeedService(
      cache: cache,
      bundledLoader: () async => raw,
      networkEnabled: false,
    );

    final first = await service.loadCached();
    final second = await service.loadCached();

    expect(first, isNotNull);
    expect(identical(first, second), isTrue);
    service.close();
  });

  test('parses strict German display prices for regular-price ingestion', () {
    final result = parseProspectFeed(r'''
{
  "generatedAt": "2026-10-15T04:15:00Z",
  "sources": [
    {"storeName": "Lidl", "status": "ok", "branchId": "lidl-zellingen"}
  ],
  "offers": [
    {
      "sourceId": "formatted-regular",
      "productLabel": "Jacobs Kaffee Crema 500 g",
      "storeName": "Lidl",
      "offerPrice": 4.99,
      "wasPrice": "7,99 €",
      "validFrom": "2026-10-13",
      "validUntil": "2026-10-17",
      "source": "retailerWebsite",
      "proofRef": "https://example.test/lidl/formatted-regular"
    }
  ]
}
''');

    expect(result.records, hasLength(1));
    expect(result.records.single.offerPrice, 4.99);
    expect(result.records.single.originalPrice, 7.99);
  });

}

