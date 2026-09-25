import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/offers/offer_import.dart';

class ProspectFeedLoadResult {
  const ProspectFeedLoadResult({
    required this.records,
    required this.refreshedStores,
    this.generatedAt,
  });

  final List<OfferImportRecord> records;
  final List<String> refreshedStores;
  final DateTime? generatedAt;
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
  for (final source in (json['sources'] as List<dynamic>? ?? const [])) {
    if (source is! Map<String, dynamic>) continue;
    if (source['status'] != 'ok') continue;
    final storeName = source['storeName'] as String?;
    if (storeName != null && storeName.trim().isNotEmpty) {
      refreshedStores.add(storeName);
    }
  }

  final records = <OfferImportRecord>[];
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
  );
}
