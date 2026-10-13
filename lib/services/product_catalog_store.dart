import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'sequential_operation_queue.dart';

class ProductCatalogStore {
  static const _key = 'custom_products_v1';
  static final _queue = SequentialOperationQueue();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<Product>> load() => _queue.schedule(_loadNow);

  Future<List<Product>> _loadNow() async {
    final values = await _preferences.getStringList(_key);
    if (values == null) return <Product>[];

    final result = <Product>[];
    for (final value in values) {
      try {
        result.add(Product.fromJson(jsonDecode(value) as Map<String, dynamic>));
      } catch (_) {
        // Defekte Einzel-Einträge werden ignoriert.
      }
    }
    return result;
  }

  Future<List<Product>> upsert(Product product, List<Product> current) {
    final snapshot = List<Product>.of(current, growable: false);
    return _queue.schedule(() async {
      final base = await _mergeWithStored(snapshot);
      final next = [product, ...base.where((item) => item.id != product.id)]
        ..sort((a, b) => a.name.compareTo(b.name));
      await _saveNow(next);
      return next;
    });
  }

  Future<List<Product>> remove(String id, List<Product> current) {
    final snapshot = List<Product>.of(current, growable: false);
    return _queue.schedule(() async {
      final next = (await _mergeWithStored(snapshot))
          .where((item) => item.id != id)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      await _saveNow(next);
      return next;
    });
  }

  Future<void> save(List<Product> products) {
    final snapshot = List<Product>.of(products, growable: false);
    return _queue.schedule(() => _saveNow(snapshot));
  }

  Future<void> _saveNow(List<Product> products) => _preferences.setStringList(
    _key,
    products.map((product) => jsonEncode(product.toJson())).toList(),
  );

  Future<List<Product>> _mergeWithStored(List<Product> current) async {
    final byId = <String, Product>{
      for (final product in await _loadNow()) product.id: product,
    };
    for (final product in current) {
      byId[product.id] = product;
    }
    return byId.values.toList();
  }
}
