import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'barcode_normalizer.dart';
import 'sequential_operation_queue.dart';

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
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync? _preferences;
  late final SharedPreferencesAsync _lazyPreferences =
      _preferences ?? SharedPreferencesAsync();

  @override
  Future<Product?> load(String ean) {
    final code = normalizeBarcode(ean);
    if (code == null) return Future<Product?>.value(null);
    return _queue.schedule(() => _loadNow(code, ean));
  }

  Future<Product?> _loadNow(String code, String ean) async {
    try {
      var raw = await _lazyPreferences.getString(_key(code));
      // Keep v1 cache entries written before barcode canonicalization usable.
      if (raw == null) {
        final legacyCodes = <String>{
          ean.trim(),
          if (code.length == 13 && code.startsWith('0')) code.substring(1),
        }..remove(code);
        for (final legacyCode in legacyCodes) {
          if (legacyCode.isEmpty) continue;
          raw = await _lazyPreferences.getString(_key(legacyCode));
          if (raw != null) break;
        }
      }
      if (raw == null || raw.trim().isEmpty) return null;
      final product = Product.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return product.ean == null || normalizeBarcode(product.ean!) != code
          ? null
          : product.copyWith(ean: code);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Product product) {
    final code = product.ean == null
        ? null
        : normalizeBarcode(product.ean!);
    if (code == null) return Future<void>.value();
    final normalizedProduct = product.copyWith(ean: code);
    final raw = jsonEncode(normalizedProduct.toJson());
    return _queue.schedule(() => _saveNow(code, raw));
  }

  Future<void> _saveNow(String code, String raw) async {
    try {
      await _lazyPreferences.setString(
        _key(code),
        raw,
      );
    } catch (_) {
      // A cache failure must never turn a successful provider response into an
      // application error.
    }
  }

  String _key(String code) => '$keyPrefix${Uri.encodeComponent(code)}';
}
