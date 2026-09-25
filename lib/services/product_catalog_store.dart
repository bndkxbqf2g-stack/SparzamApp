import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class ProductCatalogStore {
  static const _key = 'custom_products_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<Product>> load() async {
    final values = await _preferences.getStringList(_key);
    if (values == null) return <Product>[];

    final result = <Product>[];
    for (final value in values) {
      try {
        result.add(
          Product.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } catch (_) {
        // Defekte Einzel-Einträge werden ignoriert.
      }
    }
    return result;
  }

  Future<List<Product>> upsert(Product product, List<Product> current) async {
    final next = [
      product,
      ...current.where((item) => item.id != product.id),
    ]..sort((a, b) => a.name.compareTo(b.name));
    await _save(next);
    return next;
  }

  Future<List<Product>> remove(String id, List<Product> current) async {
    final next = current.where((item) => item.id != id).toList();
    await _save(next);
    return next;
  }

  Future<void> _save(List<Product> products) =>
      _preferences.setStringList(
        _key,
        products.map((product) => jsonEncode(product.toJson())).toList(),
      );
}
