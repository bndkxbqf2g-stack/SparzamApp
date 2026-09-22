import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/market_price.dart';
import '../models/product.dart';
import '../models/store.dart';

class OpenPricesService {
  OpenPricesService({
    http.Client? client,
    this.maxAge = const Duration(days: 60),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration maxAge;

  Future<List<MarketPrice>> fetchRecentPrices({
    required Product product,
    required List<Store> stores,
    DateTime? now,
  }) async {
    final ean = product.ean?.trim();
    if (ean == null || ean.isEmpty) return const <MarketPrice>[];

    final today = now ?? DateTime.now();
    final earliest = today.subtract(maxAge);
    final uri = Uri.https(
      'prices.openfoodfacts.org',
      '/api/v1/prices',
      {
        'product_code': ean,
        'currency': 'EUR',
        'price_is_discounted': 'false',
        'duplicate_of__isnull': 'true',
        'date__gte': _date(earliest),
        'order_by': '-date',
        'size': '100',
      },
    );

    final response = await _client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'SparzamApp/1.0 (Open Prices integration)',
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw http.ClientException('Open Prices HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>? ?? const <dynamic>[];
    final byStore = <String, MarketPrice>{};

    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final price = (raw['price'] as num?)?.toDouble();
      final dateRaw = raw['date'] as String?;
      final location = raw['location'] as Map<String, dynamic>?;
      if (price == null || price <= 0 || dateRaw == null || location == null) {
        continue;
      }

      final store = _matchStore(location, stores);
      if (store == null) continue;

      final observedAt = DateTime.tryParse(dateRaw);
      if (observedAt == null) continue;
      final previous = byStore[store.name];
      if (previous != null && !observedAt.isAfter(previous.updatedAt)) {
        continue;
      }

      byStore[store.name] = MarketPrice(
        productId: product.id,
        storeName: store.name,
        price: price,
        updatedAt: observedAt,
        source: MarketPriceSource.openPrices,
        externalId: (raw['id'] as num?)?.toInt(),
        sourceLocationName: _locationLabel(location),
      );
    }

    return byStore.values.toList();
  }

  Store? _matchStore(
    Map<String, dynamic> location,
    List<Store> stores,
  ) {
    final city = (location['osm_address_city'] as String?)?.trim();
    if (city == null || city.isEmpty) return null;
    final postcode = (location['osm_address_postcode'] as String?)?.trim();
    final haystack = [
      location['osm_brand'],
      location['osm_name'],
      location['osm_display_name'],
    ].whereType<String>().map(_normalize).join(' ');

    if (haystack.isEmpty) return null;

    for (final store in stores) {
      if (_normalize(store.location.split('·').first) != _normalize(city)) {
        continue;
      }
      final storePostcode = RegExp(r'\b\d{5}\b').firstMatch(store.address);
      if (postcode != null && postcode.isNotEmpty &&
          storePostcode != null && storePostcode.group(0) != postcode) {
        continue;
      }
      final needle = _normalize(store.name);
      if (needle.isNotEmpty && haystack.contains(needle)) return store;
    }
    return null;
  }

  String _locationLabel(Map<String, dynamic> location) {
    final name = (location['osm_name'] as String?)?.trim();
    final city = (location['osm_address_city'] as String?)?.trim();
    if (name != null && name.isNotEmpty && city != null && city.isNotEmpty) {
      return '$name · $city';
    }
    return name?.isNotEmpty == true
        ? name!
        : (location['osm_display_name'] as String? ?? 'Open Prices');
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  void close() => _client.close();
}
