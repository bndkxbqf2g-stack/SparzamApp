import 'dart:convert';

import 'package:http/http.dart' as http;

/// Discovery leads remain outside the confirmed MarketPrice store.
class OpenPriceLead {
  const OpenPriceLead({
    required this.id,
    required this.type,
    required this.date,
    required this.price,
    required this.currency,
    required this.productCode,
    required this.categoryTag,
    required this.locationId,
    required this.locationName,
    required this.isDiscounted,
    required this.pricePer,
  });

  final int id;
  final String type;
  final DateTime? date;
  final double? price;
  final String currency;
  final String? productCode;
  final String? categoryTag;
  final int? locationId;
  final String? locationName;
  final bool isDiscounted;
  final String? pricePer;

  /// A lead cannot be used as an exact product price without further checks.
  bool get isProductLead =>
      type == 'PRODUCT' && productCode != null;
}

class OpenPriceDiscovery {
  OpenPriceDiscovery({required this.client});
  final http.Client client;

  /// Returns at most three pages, with the caller choosing a barcode,
  /// a category, a location, or a combination. No private receipts are sent.
  Future<List<OpenPriceLead>> search({
    String? productCode,
    String? categoryTag,
    int? locationId,
    bool withoutProductCode = false,
    int maxPages = 3,
  }) async {
    if (maxPages < 1 || maxPages > 3) {
      throw ArgumentError.value(maxPages, 'maxPages');
    }
    if (productCode == null && categoryTag == null && locationId == null) {
      throw ArgumentError('Specify product, category or location.');
    }
    if (productCode != null && withoutProductCode) {
      throw ArgumentError('Barcode and productless filter conflict.');
    }
    final found = <OpenPriceLead>[];
    for (var page = 1; page <= maxPages; page++) {
      final query = <String, String>{
        'currency': 'EUR',
        'size': '50',
        'page': '$page',
        'duplicate_of__isnull': 'true',
        if (withoutProductCode) 'product_code__isnull': 'true',
      };
      if (productCode != null) {
        query['product_code'] = productCode;
      }
      if (categoryTag != null) {
        query['category_tag'] = categoryTag;
      }
      if (locationId != null) {
        query['location_id'] = '$locationId';
      }
      final uri = Uri.https(
          'prices.openfoodfacts.org', '/api/v1/prices', query);
      final response = await client.get(uri, headers: const {
        'Accept': 'application/json',
        'User-Agent': 'SparzamApp/1.0 (price discovery)',
      }).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw http.ClientException('Open Prices HTTP ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      for (final raw in (data['items'] as List<dynamic>? ?? const [])) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }
        if (raw['currency'] != 'EUR' || raw['duplicate_of'] != null) {
          continue;
        }
        final location = raw['location'] as Map<String, dynamic>?;
        final price = raw['price'];
        final numericPrice = price is num ? price.toDouble() : null;
        if (numericPrice != null &&
            (!numericPrice.isFinite || numericPrice <= 0)) {
          continue;
        }
        found.add(OpenPriceLead(
          id: (raw['id'] as num?)?.toInt() ?? -1,
          type: raw['type'] as String? ?? '',
          date: DateTime.tryParse(raw['date'] as String? ?? ''),
          price: numericPrice,
          currency: 'EUR',
          productCode: raw['product_code'] as String?,
          categoryTag: raw['category_tag'] as String?,
          locationId: (raw['location_id'] as num?)?.toInt(),
          locationName: location?['osm_name'] as String?,
          isDiscounted: raw['price_is_discounted'] == true,
          pricePer: raw['price_per'] as String?,
        ));
      }
      final pages = (data['pages'] as num?)?.toInt() ?? page;
      if (page >= pages) {
        break;
      }
    }
    return found;
  }
}
