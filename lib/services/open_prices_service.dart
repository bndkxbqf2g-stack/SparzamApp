import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/market_price.dart';
import '../models/product.dart';
import '../models/store.dart';
import 'open_prices_cache.dart';
import 'price_source.dart';
import 'store_identity.dart';

/// Read-only adapter for the documented Open Prices API.
///
/// Open Prices contributes observations, not confirmed product identity. The
/// store matcher therefore requires an exact configured branch when available
/// and otherwise still requires the configured chain plus city/postcode.
class OpenPricesSource implements PriceSource {
  OpenPricesSource({
    http.Client? client,
    this.maxAge = const Duration(days: 60),
    this.cache,
    this.enabled = true,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration maxAge;
  final OpenPricesCache? cache;

  @override
  final bool enabled;

  @override
  Future<List<MarketPrice>> fetchRecentPrices({
    required Product product,
    required List<Store> stores,
    DateTime? now,
  }) async {
    if (!enabled) return const <MarketPrice>[];

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

    String? body;
    var fromCache = false;
    try {
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
      body = response.body;
      try {
        await cache?.save(ean, body);
      } catch (_) {
        // Cache availability must never block a valid live response.
      }
    } catch (error, stackTrace) {
      body = await _loadCached(ean);
      if (body == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      fromCache = true;
    }

    try {
      return _parse(
        body!,
        product: product,
        stores: stores,
        today: today,
        earliest: earliest,
        allowStale: fromCache,
      );
    } catch (error, stackTrace) {
      // A malformed live response must not hide a previously validated cache.
      if (!fromCache) {
        final cached = await _loadCached(ean);
        if (cached != null) {
          try {
            return _parse(
              cached,
              product: product,
              stores: stores,
              today: today,
              earliest: earliest,
              allowStale: true,
            );
          } catch (_) {
            // Fall through and preserve the original parse error.
          }
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  List<MarketPrice> _parse(
    String body, {
    required Product product,
    required List<Store> stores,
    required DateTime today,
    required DateTime earliest,
    required bool allowStale,
  }) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>? ?? const <dynamic>[];
    final byStore = <String, MarketPrice>{};

    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      if (raw['product_code']?.toString() != product.ean?.trim() ||
          raw['currency'] != 'EUR' ||
          raw['price_is_discounted'] != false ||
          raw['price_per'] != 'UNIT' ||
          raw['duplicate_of'] != null ||
          (raw['type'] != null && raw['type'] != 'PRODUCT')) {
        continue;
      }
      final price = (raw['price'] as num?)?.toDouble();
      final dateRaw = raw['date'] as String?;
      final locationRaw = raw['location'];
      final location = locationRaw is Map
          ? locationRaw.cast<String, dynamic>()
          : null;
      if (price == null ||
          !price.isFinite ||
          price <= 0 ||
          dateRaw == null ||
          location == null) {
        continue;
      }

      final store = _matchStore(location, stores);
      if (store == null) continue;

      final observedAt = DateTime.tryParse(dateRaw);
      if (observedAt == null) continue;
      final observedDay = DateTime(
        observedAt.year,
        observedAt.month,
        observedAt.day,
      );
      final earliestDay = DateTime(earliest.year, earliest.month, earliest.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      if ((!allowStale && observedDay.isBefore(earliestDay)) ||
          observedDay.isAfter(todayDay)) {
        continue;
      }

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
        sourceLocationId: _locationId(location),
        sourceLocationName: _locationLabel(location),
      );
    }

    return byStore.values.toList();
  }

  Store? _matchStore(
    Map<String, dynamic> location,
    List<Store> stores,
  ) {
    final locationId = _locationId(location);
    if (locationId != null) {
      for (final store in stores) {
        if (store.branchId?.trim() == locationId) return store;
      }
    }

    final city = (location['osm_address_city'] as String?)?.trim();
    if (city == null || city.isEmpty) return null;
    final postcode = (location['osm_address_postcode'] as String?)?.trim();
    final labels = [
      location['osm_brand'],
      location['osm_name'],
      location['osm_display_name'],
    ].whereType<String>();

    if (labels.isEmpty) return null;

    for (final store in stores) {
      if (normalizeStoreIdentityText(store.location.split('·').first) !=
          normalizeStoreIdentityText(city)) {
        continue;
      }
      final storePostcode = RegExp(r'\b\d{5}\b').firstMatch(store.address);
      if (postcode != null &&
          postcode.isNotEmpty &&
          storePostcode != null &&
          storePostcode.group(0) != postcode) {
        continue;
      }
      final matched = labels.any(
        (label) => canonicalStoreName(label, [store]) == store.name,
      );
      if (matched) return store;
    }
    return null;
  }

  String? _locationId(Map<String, dynamic> location) {
    for (final key in const ['id', 'location_id', 'osm_id']) {
      final value = location[key];
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
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

  Future<String?> _loadCached(String ean) async {
    try {
      return await cache?.load(ean);
    } catch (_) {
      return null;
    }
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  void close() => _client.close();
}

/// Compatibility name used by the existing UI and sync flow.
typedef OpenPricesService = OpenPricesSource;
