import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// Local cache for external product enrichment. The cache contains product
/// metadata only; it never makes a price or identity claim.
abstract interface class ProductDataCache {
  Future<Product?> load(String ean);

  Future<void> save(Product product);
}

/// Small-device cache backed by the existing local-only preferences store.
class SharedPreferencesProductDataCache implements ProductDataCache {
  SharedPreferencesProductDataCache({this._preferences});

  static const keyPrefix = 'product_data_cache_v1|';
  final SharedPreferencesAsync? _preferences;
  late final SharedPreferencesAsync _lazyPreferences =
      _preferences ?? SharedPreferencesAsync();

  @override
  Future<Product?> load(String ean) async {
    final code = ean.trim();
    if (code.isEmpty) return null;
    try {
      final raw = await _lazyPreferences.getString(_key(code));
      if (raw == null || raw.trim().isEmpty) return null;
      final product = Product.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return product.ean?.trim() == code ? product : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Product product) async {
    final code = product.ean?.trim();
    if (code == null || code.isEmpty) return;
    try {
      await _lazyPreferences.setString(
        _key(code),
        jsonEncode(product.toJson()),
      );
    } catch (_) {
      // A cache failure must never turn a successful provider response into an
      // application error.
    }
  }

  String _key(String code) => '$keyPrefix${Uri.encodeComponent(code)}';
}
