import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/market_price.dart';
import '../models/product.dart';
import '../models/store.dart';
import 'barcode_normalizer.dart';
import 'open_prices_cache.dart';
import 'branch_identity.dart';
import 'price_source.dart';
import 'store_identity.dart';
import 'quantity_normalizer.dart';

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

    final ean = product.ean == null
        ? null
        : normalizeBarcode(product.ean!);
    if (ean == null) return const <MarketPrice>[];

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
        body,
        ean: ean,
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
              ean: ean,
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
    required String ean,
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
      if (normalizeBarcode(raw['product_code']?.toString() ?? '') != ean ||
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

      // Open Prices marks `price_per=UNIT`, so the value describes the
      // product unit queried by EAN. Preserve the catalog package basis at
      // the adapter boundary; this lets the shared comparability gate reject
      // a known package mismatch and expose a trustworthy base price.
      final packageAmount = product.packageAmount;
      final packageUnit = product.packageUnit?.trim();
      final unitPrice = packageAmount == null ||
              packageUnit == null ||
              packageUnit.isEmpty
          ? null
          : normalizedUnitPrice(
              price: price,
              amount: packageAmount,
              unit: packageUnit,
            );

      byStore[store.name] = MarketPrice(
        productId: product.id,
        storeName: store.name,
        price: price,
        updatedAt: observedAt,
        source: MarketPriceSource.openPrices,
        externalId: (raw['id'] as num?)?.toInt(),
        sourceLocationId: _locationId(location),
        sourceLocationName: _locationLabel(location),
        quantity: packageAmount,
        unit: packageUnit,
        unitPrice: unitPrice,
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
      final idMatches = stores
          .where(
            (store) =>
                canonicalBranchId(store.branchId) ==
                canonicalBranchId(locationId),
          )
          .toList(growable: false);
      if (idMatches.length == 1) {
        final candidate = idMatches.single;
        // A provider ID is useful evidence, but contradictory city/postcode
        // or an explicitly recognized retailer label must still reject the
        // record. This prevents a malformed source row from assigning a
        // correct branch ID to the wrong market context.
        return _locationContextMatches(location, candidate, stores)
            ? candidate
            : null;
      }
      if (idMatches.length > 1) {
        final contextualMatches = idMatches
            .where((store) => _locationContextMatches(location, store, stores))
            .toList(growable: false);
        return contextualMatches.length == 1 ? contextualMatches.single : null;
      }
    }

    final city = (location['osm_address_city'] as String?)?.trim();
    if (city == null || city.isEmpty) return null;
    final labels = _locationLabels(location);
    if (labels.isEmpty) return null;

    for (final store in stores) {
      if (normalizeStoreIdentityText(store.location.split('·').first) !=
          normalizeStoreIdentityText(city)) {
        continue;
      }
      if (!_locationContextMatches(location, store, stores)) continue;
      final matched = labels.any(
        (label) => canonicalStoreName(label, [store]) == store.name,
      );
      if (matched) return store;
    }
    return null;
  }

  bool _locationContextMatches(
    Map<String, dynamic> location,
    Store store,
    List<Store> stores,
  ) {
    final city = (location['osm_address_city'] as String?)?.trim();
    if (city != null &&
        city.isNotEmpty &&
        normalizeStoreIdentityText(store.location.split('·').first) !=
            normalizeStoreIdentityText(city)) {
      return false;
    }

    final postcode = _postcode(location['osm_address_postcode']);
    final storePostcode =
        RegExp(r'\b\d{5}\b').firstMatch(store.address)?.group(0);
    if (postcode != null &&
        storePostcode != null &&
        postcode != storePostcode) {
      return false;
    }

    final recognizedLabels = _locationLabels(location)
        .map((label) => canonicalStoreName(label, stores))
        .whereType<String>()
        .toSet();
    return recognizedLabels.isEmpty || recognizedLabels.contains(store.name);
  }

  List<String> _locationLabels(Map<String, dynamic> location) => [
        location['osm_brand'],
        location['osm_name'],
        location['osm_display_name'],
      ]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);

  String? _postcode(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return RegExp(r'\b\d{5}\b').firstMatch(text)?.group(0);
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
