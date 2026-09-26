import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/offers/offer_import.dart';

class ProspectFeedLoadResult {
  const ProspectFeedLoadResult({
    required this.records,
    required this.refreshedStores,
    this.generatedAt,
    this.prospects = const <ProspectIssue>[],
  });

  final List<OfferImportRecord> records;
  final List<String> refreshedStores;
  final DateTime? generatedAt;
  final List<ProspectIssue> prospects;
}

class ProspectIssue {
  const ProspectIssue({required this.storeName, required this.title, required this.pages, this.url, this.thumbnailUrl});
  final String storeName;
  final String title;
  final List<ProspectPage> pages;
  final String? url;
  final String? thumbnailUrl;
}

class ProspectPage {
  const ProspectPage({required this.number, required this.imageUrl, this.zoomUrl, this.keyWords = ''});
  final int number;
  final String imageUrl;
  final String? zoomUrl;
  final String keyWords;
}

String? _officialProspectUrl(String storeName, String? fallback) {
  switch (storeName) {
    case 'ALDI Süd':
      return 'https://prospekt.aldi-sued.de/kw39-26-op-mp/page/1';
    case 'EDEKA':
      return 'https://www.edeka.de/markt-id/8002976/prospekt.jsp';
    case 'Kaufland':
      return 'https://filiale.kaufland.de/prospekte.html';
    case 'PENNY':
      return 'https://www.penny.de/angebote';
    case 'Netto':
      return 'https://www.netto-online.de/ueber-netto/Online-Prospekte.chtm/4371';
    case 'REWE':
      return 'https://www.rewe.de/marktseite/veitshoechheim/461683/rewe-markt-pont-l-eveque-allee-1/';
    default:
      return fallback;
  }
}

class ProspectFeedService {
  ProspectFeedService({http.Client? client}) : _client = client ?? http.Client();

  static const feedUrl =
      'https://raw.githubusercontent.com/bndkxbqf2g-stack/SparzamApp/'
      'main/assets/prospects/current.json';

  final http.Client _client;

  Future<ProspectFeedLoadResult> load() async {
    final response = await _client
        .get(Uri.parse(feedUrl))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Prospektfeed HTTP \${response.statusCode}');
    }
    return parseProspectFeed(response.body);
  }
}

ProspectFeedLoadResult parseProspectFeed(String raw) {
  final json = jsonDecode(raw);
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Ungültiger Prospektfeed');
  }

  final generatedAt = DateTime.tryParse(json['generatedAt'] as String? ?? '');
  final refreshedStores = <String>[];
  final availableStores = <String>[];
  final availableStoreUrls = <String, String>{};
  for (final source in (json['sources'] as List<dynamic>? ?? const [])) {
    if (source is! Map<String, dynamic>) continue;
    final storeName = source['storeName'] as String?;
    if (storeName == null || storeName.trim().isEmpty) continue;
    if (!availableStores.contains(storeName)) {
      availableStores.add(storeName);
    }
    final sourceUrl = source['url'] as String?;
    if (sourceUrl != null && sourceUrl.trim().isNotEmpty) {
      availableStoreUrls[storeName] = sourceUrl;
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
          pages.add(ProspectPage(number: number, imageUrl: image, zoomUrl: page['zoom'] as String?, keyWords: page['keyWords'] as String? ?? ''));
        }
      }
      if (pages.isNotEmpty) {
        prospects.add(ProspectIssue(storeName: storeName, title: raw['title'] as String? ?? 'Prospekt', pages: pages, url: raw['url'] as String?, thumbnailUrl: raw['thumbnailUrl'] as String?));
      }
    }
  }
  // Jeder konfigurierte Markt bleibt in der Prospektansicht sichtbar.
  // Einige Händler liefern aktuell nur strukturierte Angebote, aber noch keine
  // Bildseiten. Für diese Märkte zeigt die App eine informative Platzhalterkarte.
  final storesWithPages = prospects.map((issue) => issue.storeName).toSet();
  for (final storeName in availableStores) {
    if (!storesWithPages.contains(storeName)) {
      prospects.add(
        ProspectIssue(
          storeName: storeName,
          title: 'Aktionsprospekt',
          pages: const <ProspectPage>[],
          url: _officialProspectUrl(storeName, availableStoreUrls[storeName]),
        ),
      );
    }
  }

  for (final value in (json['offers'] as List<dynamic>? ?? const [])) {
    if (value is! Map<String, dynamic>) continue;
    final sourceId = value['sourceId'] as String?;
    final productLabel = value['productLabel'] as String?;
    final storeName = value['storeName'] as String?;
    final offerPrice = (value['offerPrice'] as num?)?.toDouble();
    final validUntil =
        DateTime.tryParse(value['validUntil'] as String? ?? '');
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

    final originalPrice = (value['originalPrice'] as num?)?.toDouble();
    records.add(
      OfferImportRecord(
        sourceId: sourceId,
        productLabel: productLabel,
        storeName: storeName,
        originalPrice:
            originalPrice != null && originalPrice.isFinite && originalPrice > 0
                ? originalPrice
                : null,
        offerPrice: offerPrice,
        validFrom: DateTime.tryParse(value['validFrom'] as String? ?? ''),
        validUntil: validUntil,
        source: value['source'] as String? ?? 'retailerWebsite',
        proofRef: value['proofRef'] as String?,
        imageUrl: value['imageUrl'] as String?,
      ),
    );
  }

  return ProspectFeedLoadResult(
    records: records,
    refreshedStores: refreshedStores,
    generatedAt: generatedAt,
    prospects: prospects,
  );
}
